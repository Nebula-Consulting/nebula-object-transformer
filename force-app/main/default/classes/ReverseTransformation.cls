/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 17/11/2021
 * @description (if required)
 */

public inherited sharing class ReverseTransformation extends Transformation {

    public ReverseTransformation(String transformationName, Type targetType) {
        this(
        [
                SELECT Source_Field__c, Target_Field__c, Apex_Class__c
                FROM Transformation_Field__mdt
                WHERE Transformation__r.DeveloperName = :transformationName
        ],
                targetType);
    }

    @TestVisible
    private ReverseTransformation(List<Transformation_Field__mdt> transformationFields, Type targetType) {
        super(new nebc.LazySObjectIterator(transformationFields.deepClone())
                .mapValuesT(new SwapFields(Transformation_Field__mdt.Source_Field__c, Transformation_Field__mdt.Target_Field__c))
                .toList(new List<Transformation_Field__mdt>()), targetType);
    }
}