/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 10/11/2021
 * @description Transforms "Gettable" objects into "Puttable" objects with the transformations defined by
 * Transformation_Field__mdt records
 */

public inherited sharing class Transformation implements nebc.Function {

    private List<Transformation_Field__mdt> transformMetadata;
    private Type targetType;
    private nebc.SObjectIndex targetFieldToTransformMetadata;

    public Transformation(String transformationName, Type targetType) {
        this(
        [
                SELECT Source_Field__c, Target_Field__c, Apex_Class__c
                FROM Transformation_Field__mdt
                WHERE Transformation__r.DeveloperName = :transformationName
        ],
                targetType);
    }

    @TestVisible
    private Transformation(List<Transformation_Field__mdt> transformationFields, Type targetType) {
        this.transformMetadata = transformationFields;
        this.targetType = targetType;

        targetFieldToTransformMetadata = new nebc.SObjectIndex(Transformation_Field__mdt.Target_Field__c)
                .putAll(transformationFields);
    }

    public Transformation getReverse(Type targetType) {
        return new Transformation(
                new nebc.LazySObjectIterator(transformMetadata)
                        .mapValuesT(new SwapFields(Transformation_Field__mdt.Source_Field__c, Transformation_Field__mdt.Target_Field__c))
                        .toList(new List<Transformation_Field__mdt>()),
                targetType);
    }

    public Object call(Object inputToTransform) {
        Object result = targetType.newInstance();

        nebc.Function transformMetadataToValue = new nebc.Composition(new nebc.FieldFromSObject(Transformation_Field__mdt.Source_Field__c))
                .compose(new ReplaceNullWith('Id'))
                .compose(new nebc.GetFrom(inputToTransform));

        new nebc.LazySObjectIterator(transformMetadata)
                .mapValues(new nebc.ToTwoTuple(new nebc.FieldFromSObject(Transformation_Field__mdt.Target_Field__c), transformMetadataToValue))
                .mapValues(new FieldAndValueToTransformedValueTuple(targetFieldToTransformMetadata))
                .forEach(new nebc.PutTo(result));

        return result;
    }

    public Set<String> getSourceFields() {
        return new nebc.LazySObjectIterator(transformMetadata).get(Transformation_Field__mdt.Source_Field__c, new Set<String>());
    }

    private class FieldAndValueToTransformedValueTuple implements nebc.Function {

        private nebc.Function sourceFieldToTransformationFunction;

        public FieldAndValueToTransformedValueTuple(nebc.SObjectIndex targetFieldToTransformMetadata) {
            sourceFieldToTransformationFunction = new nebc.Composition(new nebc.GetFrom(targetFieldToTransformMetadata))
                    .compose(new TransformMetadataToTransformFunction());
        }

        public Object call(Object o) {
            nebc.Tuple fieldAndValue = (nebc.Tuple)o;
            String field = (String)fieldAndValue.get(0);
            return new nebc.TwoTuple(field, ((nebc.Function)sourceFieldToTransformationFunction.call(field)).call(fieldAndValue.get(1)));
        }
    }

    private class TransformMetadataToTransformFunction implements nebc.Function {

        public Object call(Object o) {
            Transformation_Field__mdt transformationFieldMetadata = (Transformation_Field__mdt)o;
            String typeName = transformationFieldMetadata.Apex_Class__c == null ? nebc.IdentityFunction.class.getName() : transformationFieldMetadata.Apex_Class__c;

            return nebc.TypeLoader.getInstance(nebc.TypeLoader.getType(typeName), transformationFieldMetadata.Apex_Class_Parameters__c);
        }
    }

    private class ReplaceNullWith implements nebc.Function {

        private Object value;

        public ReplaceNullWith(Object value) {
            this.value = value;
        }

        public Object call(Object o) {
            return  o == null ? value : o;
        }
    }
}