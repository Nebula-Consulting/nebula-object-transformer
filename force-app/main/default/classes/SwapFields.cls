/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 17/11/2021
 * @description Function to swap the values in two fields of an SObject
 */

public with sharing class SwapFields implements nebc.Function {

    private SObjectField field1;
    private SObjectField field2;

    public SwapFields(SObjectField field1, SObjectField field2) {
        this.field1 = field1;
        this.field2 = field2;
    }

    public SObject call(Object o) {
        SObject theSObject = (SObject)o;
        Object value = theSObject.get(field1);
        theSObject.put(field1, theSObject.get(field2));
        theSObject.put(field2, value);

        return theSObject;
    }
}