/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 10/11/2021
 * @description Transforms "Gettable" objects into "Puttable" objects with the transformations defined by
 * Transformation_Field__mdt records
 */

global virtual inherited sharing class Transformation implements nebc.Function {

    private List<nebc.Tuple> metadataAndFunction;
    private Type targetType;

    private static nebc.Function metadataAndFunctionToTargetField = new nebc.Composition(new nebc.Left()).compose(new nebc.FieldFromSObject(Transformation_Field__mdt.Target_Field__c));
    private static nebc.Function metadataToSourceField = new nebc.FieldFromSObject(Transformation_Field__mdt.Source_Field__c);

    /**
     * @param transformationName The DeveloperName of a Transformation__mdt record to use
     * @param targetType The type to construct as output, can be an SObject or Map<String, Object>
     */
    global Transformation(String transformationName, Type targetType) {
        this(
        [
                SELECT Source_Field__c, Target_Field__c, Apex_Class__c
                FROM Transformation_Field__mdt
                WHERE Transformation__r.DeveloperName = :transformationName
        ],
                targetType);
    }

    @TestVisible
    protected Transformation(List<Transformation_Field__mdt> transformationMetadata, Type targetType) {
        this.metadataAndFunction = (List<nebc.Tuple>)new nebc.LazySObjectIterator(transformationMetadata)
                .putIf(new nebc.IsNull(Transformation_Field__mdt.Source_Field__c), Transformation_Field__mdt.Source_Field__c, 'Id')
                .putIf(new nebc.IsNull(Transformation_Field__mdt.Apex_Class__c), Transformation_Field__mdt.Apex_Class__c, nebc.IdentityFunction.class.getName())
                .mapValues(new nebc.ToTwoTuple(new nebc.IdentityFunction(), new MetadataToTransformFunctionInstance()))
                .toList(new List<nebc.Tuple>());
        this.targetType = targetType;
    }

    global Object call(Object inputToTransform) {
        Object result = targetType.newInstance();

        new nebc.LazySObjectIterator(metadataAndFunction)
                .mapValues(new nebc.TupleMapFunction(metadataAndFunctionToTargetField, getMetadataAndFunctionToTransformedValue(inputToTransform))
                    .setTupleNewInstance(nebc.TwoTuple.newInstance))
                .forEach(new nebc.PutTo(result));

        return result;
    }

    /**
     * Gets the fields used in the transformation in case they are required for a SOQL query or similar
     *
     * @return the fields used in the transformation
     */
    global Set<String> getSourceFields() {
        return new nebc.LazyIterator(metadataAndFunction)
                .mapValues(new nebc.Left())
                .mapValues(new nebc.FieldFromSObject(Transformation_Field__mdt.Source_Field__c))
                .toSet(new Set<String>());
    }

    private nebc.Function getMetadataAndFunctionToTransformedValue(Object inputToTransform) {
        nebc.Function metadataToValue = new nebc.Composition(metadataToSourceField)
                .compose(new nebc.GetFrom(inputToTransform));

        return new nebc.Composition(new nebc.TwoTupleMapValues(metadataToValue, new nebc.IdentityFunction()))
                .compose(new ApplyRightToLeft());
    }

    private class ApplyRightToLeft implements nebc.Function {

        public Object call(Object o) {
            nebc.Tuple tuple = (nebc.Tuple)o;
            return ((nebc.Function)tuple.get(1)).call(tuple.get(0));
        }
    }

    private class MetadataToTransformFunctionInstance implements nebc.Function {

        public Object call(Object o) {
            Transformation_Field__mdt transformationFieldMetadata = (Transformation_Field__mdt)o;
            Type transformationType = nebc.TypeLoader.getType(transformationFieldMetadata.Apex_Class__c);
            return (nebc.Function) nebc.TypeLoader.getInstance(transformationType, transformationFieldMetadata.Apex_Class_Parameters__c);
        }
    }
}