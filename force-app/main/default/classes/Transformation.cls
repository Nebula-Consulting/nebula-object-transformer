/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 10/11/2021
 * @description Transforms "Gettable" objects into "Puttable" objects with the transformations defined by
 * Transformation_Field__mdt records
 */

public virtual inherited sharing class Transformation implements nebc.Function {

    private List<Transformation_Field__mdt> transformMetadata;
    private Type targetType;
    private static nebc.Function transformField = new nebc.FieldFromSObject(Transformation_Field__mdt.Target_Field__c);

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
    protected Transformation(List<Transformation_Field__mdt> transformationFields, Type targetType) {
        this.transformMetadata = transformationFields;
        this.targetType = targetType;
    }

    public Object call(Object inputToTransform) {
        Object result = targetType.newInstance();

        new nebc.LazySObjectIterator(transformMetadata)
                .mapValues(new nebc.ToTwoTuple(transformField, new TransformValue(inputToTransform)))
                .forEach(new nebc.PutTo(result));

        return result;
    }

    public Set<String> getSourceFields() {
        return new nebc.LazySObjectIterator(transformMetadata).get(Transformation_Field__mdt.Source_Field__c, new Set<String>());
    }

    private class TransformValue implements nebc.Function {

        private Object inputToTransform;

        public TransformValue(Object inputToTransform) {
            this.inputToTransform = inputToTransform;
        }

        public Object call(Object o) {
            Transformation_Field__mdt transformationFieldMetadata = (Transformation_Field__mdt)o;

            Object sourceValue = transformationFieldMetadata.Source_Field__c == null ? null : new nebc.GetFrom(inputToTransform).call(transformationFieldMetadata.Source_Field__c);

            if(transformationFieldMetadata.Apex_Class__c == null) {
                return sourceValue;
            } else {
                return getTransformFunction(transformationFieldMetadata).call(sourceValue);
            }
        }

        private nebc.Function getTransformFunction(Transformation_Field__mdt transformationFieldMetadata) {
            Type transformationType = nebc.TypeLoader.getType(transformationFieldMetadata.Apex_Class__c);
            return (nebc.Function)nebc.TypeLoader.getInstance(transformationType, transformationFieldMetadata.Apex_Class_Parameters__c);
        }
    }
}