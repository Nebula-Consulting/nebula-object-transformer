/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 17/11/2021
 * @description A Transformation instance that maps fields in the reverse of the configured direction
 */

global inherited sharing class ReverseTransformation extends Transformation {

    global ReverseTransformation(String transformationName, Type targetType) {
        this(
                [
                        SELECT Source_Field__c, Target_Field__c, Apex_Class__c, Apex_Class_Parameters__c, Apex_Class_Receives__c,
                                Reverse_Apex_Class__c, Reverse_Apex_Class_Parameters__c, Reverse_Apex_Class_Receives__c,
                                Target_Is_Read_Only__c, Source_Is_Read_Only__c
                        FROM Transformation_Field__mdt
                        WHERE Transformation__r.DeveloperName = :transformationName
                ],
                targetType);
    }

    global ReverseTransformation(String transformationName, Iterator<Object> targetObjectIterator) {
        this(
                [
                        SELECT Source_Field__c, Target_Field__c, Apex_Class__c, Apex_Class_Parameters__c, Apex_Class_Receives__c,
                                Reverse_Apex_Class__c, Reverse_Apex_Class_Parameters__c, Reverse_Apex_Class_Receives__c,
                                Target_Is_Read_Only__c, Source_Is_Read_Only__c
                        FROM Transformation_Field__mdt
                        WHERE Transformation__r.DeveloperName = :transformationName
                ],
                targetObjectIterator);
    }

    global ReverseTransformation(List<Transformation_Field__mdt> transformationFields, Type targetType) {
        this(transformationFields, new NewInstanceGenerator(targetType));
    }

    global ReverseTransformation(List<Transformation_Field__mdt> transformationFields, Iterator<Object> targetObjectIterator) {
        super(new LazySObjectIterator(transformationFields.deepClone())
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Source_Field__c, Transformation_Field__mdt.Target_Field__c))
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Apex_Class__c, Transformation_Field__mdt.Reverse_Apex_Class__c))
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Apex_Class_Parameters__c, Transformation_Field__mdt.Reverse_Apex_Class_Parameters__c))
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Apex_Class_Receives__c, Transformation_Field__mdt.Reverse_Apex_Class_Receives__c))
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Source_Is_Read_Only__c, Transformation_Field__mdt.Target_Is_Read_Only__c))
                .toList(new List<Transformation_Field__mdt>()), targetObjectIterator);
    }
}