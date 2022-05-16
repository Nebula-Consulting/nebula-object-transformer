/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 10/11/2021
 * @description Transforms "Gettable" objects into "Puttable" objects with the transformations defined by
 * Transformation_Field__mdt records
 */

global virtual inherited sharing class Transformation implements Function {

    private List<Tuple> metadataAndFunction;
    private Iterator<Object> targetObjectIterator;

    private static Function metadataAndFunctionToTargetField = new Composition(new Left()).compose(new FieldFromSObject(Transformation_Field__mdt.Target_Field__c));

    /**
     * @param transformationName The DeveloperName of a Transformation__mdt record to use
     * @param targetType The type to construct as output, can be an SObject or Map<String, Object>
     */
    global Transformation(String transformationName, Type targetType) {
        this(
        [
                SELECT Source_Field__c, Target_Field__c, Apex_Class__c, Apex_Class_Parameters__c, Apex_Class_Receives__c,
                        Reverse_Apex_Class__c, Reverse_Apex_Class_Parameters__c, Reverse_Apex_Class_Receives__c
                FROM Transformation_Field__mdt
                WHERE Transformation__r.DeveloperName = :transformationName
        ],
                targetType);
    }

    /**
     * @param transformationName The DeveloperName of a Transformation__mdt record to use
     * @param targetObjectIterator An iterator of target objects to map to. Can be an SObjects or Map<String, Object>s
     */
    global Transformation(String transformationName, Iterator<Object> targetObjectIterator) {
        this(
        [
                SELECT Source_Field__c, Target_Field__c, Apex_Class__c, Apex_Class_Parameters__c, Apex_Class_Receives__c,
                        Reverse_Apex_Class__c, Reverse_Apex_Class_Parameters__c, Reverse_Apex_Class_Receives__c
                FROM Transformation_Field__mdt
                WHERE Transformation__r.DeveloperName = :transformationName
        ],
                targetObjectIterator);
    }

    @TestVisible
    protected Transformation(List<Transformation_Field__mdt> transformationMetadata, Type targetType) {
        this.metadataAndFunction = (List<Tuple>)new LazySObjectIterator(transformationMetadata)
                .putIf(new IsNull(Transformation_Field__mdt.Source_Field__c), Transformation_Field__mdt.Source_Field__c, 'Id')
                .putIf(new IsNull(Transformation_Field__mdt.Apex_Class__c), Transformation_Field__mdt.Apex_Class__c, IdentityFunction.class.getName())
                .mapValues(new ToTwoTuple(new IdentityFunction(), new MetadataToTransformFunctionInstance()))
                .toList(new List<Tuple>());
        this.targetObjectIterator = new NewInstanceGenerator(targetType);
    }

    @TestVisible
    protected Transformation(List<Transformation_Field__mdt> transformationMetadata, Iterator<Object> targetObjectIterator) {
        this.metadataAndFunction = (List<Tuple>)new LazySObjectIterator(transformationMetadata)
                .putIf(new IsNull(Transformation_Field__mdt.Source_Field__c), Transformation_Field__mdt.Source_Field__c, 'Id')
                .putIf(new IsNull(Transformation_Field__mdt.Apex_Class__c), Transformation_Field__mdt.Apex_Class__c, IdentityFunction.class.getName())
                .mapValues(new ToTwoTuple(new IdentityFunction(), new MetadataToTransformFunctionInstance()))
                .toList(new List<Tuple>());
        this.targetObjectIterator = targetObjectIterator;
    }

    global Object call(Object inputToTransform) {
        Object result = targetObjectIterator.next();

        Function metadataAndFunctionToFunctionInput = new IfThen(
                new IsValueTransform(),
                new Composition(new Left())
                        .compose(new FieldFromSObject(Transformation_Field__mdt.Source_Field__c))
                        .compose(new GetFrom(inputToTransform)))
                .elseFunction(
                        new ToTwoTuple(new Left(), new ConstantFunction(inputToTransform))
                );

        Function metadataAndFunctionToTransformedValue = new Composition(new TupleMapFunction(metadataAndFunctionToFunctionInput, new Right()))
                .compose(new ApplyFunctionInPosition(1).toPosition(0));

        new LazySObjectIterator(metadataAndFunction)
                .filter(new Left(), new IsNotNull(Transformation_Field__mdt.Target_Field__c))
                .mapValues(new TupleMapFunction(metadataAndFunctionToTargetField, metadataAndFunctionToTransformedValue)
                    .setTupleNewInstance(TwoTuple.newInstance))
                .forEach(new PutTo(result));

        return result;
    }

    /**
     * Gets the fields used in the transformation in case they are required for a SOQL query or similar
     *
     * @return the fields used in the transformation
     */
    global Set<String> getSourceFields() {
        return new LazyIterator(metadataAndFunction)
                .mapValues(new Left())
                .mapValues(new FieldFromSObject(Transformation_Field__mdt.Source_Field__c))
                .toSet(new Set<String>());
    }

    private class ApplyFunctionInPosition implements Function {

        private Integer functionIndex;
        private Integer valueIndex;

        public ApplyFunctionInPosition(Integer functionIndex) {
            this.functionIndex = functionIndex;
        }

        public ApplyFunctionInPosition toPosition(Integer valueIndex) {
            this.valueIndex = valueIndex;
            return this;
        }

        public Object call(Object o) {
            Tuple tuple = (Tuple)o;
            return ((Function)tuple.get(functionIndex)).call(tuple.get(valueIndex));
        }
    }

    private class MetadataToTransformFunctionInstance implements Function {

        public Object call(Object o) {
            Transformation_Field__mdt transformationFieldMetadata = (Transformation_Field__mdt)o;
            Type transformationType = TypeLoader.getType(transformationFieldMetadata.Apex_Class__c);
            if(transformationType == null) {
                throw new ClassNotFoundException('Transformation Apex Class ' + transformationFieldMetadata.Apex_Class__c + ' not found. Is it global? Does it need to include a namespace?');
            }
            try {
                return TypeLoader.getInstance(transformationType, transformationFieldMetadata.Apex_Class_Parameters__c);
            } catch (JSONException e) {
                throw new JSONException('Transformation Apex Class ' + transformationFieldMetadata.Apex_Class__c + ' must be annotated with @JsonAccess(deserializable=\'always\')', e);
            }
        }
    }

    private class IsValueTransform implements BooleanFunction {

        public Boolean isTrueFor(Object o) {
            Transformation_Field__mdt transformationFieldMetadata = (Transformation_Field__mdt)((Tuple)o).get(0);

            return transformationFieldMetadata.Apex_Class__c != null && transformationFieldMetadata.Apex_Class_Receives__c != 'Whole Object';
        }
    }
}