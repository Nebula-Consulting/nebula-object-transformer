/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 15/11/2021
 */

@IsTest
private class TransformationTest {

    @IsTest
    static void passThroughSObjectToOtherSObject() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(theLead.FirstName, newContact.FirstName);
        System.assertEquals(theLead.LastName, newContact.LastName);
        Set<String> fields = thisTransformation.getSourceFields();
        System.assertEquals(2, fields.size());
        System.assert(fields.contains('FirstName'));
        System.assert(fields.contains('LastName'));
    }

    @IsTest
    static void noTargetField() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(null, newContact.FirstName);
        System.assertEquals(theLead.LastName, newContact.LastName);
        Set<String> fields = thisTransformation.getSourceFields();
        System.assertEquals(2, fields.size());
        System.assert(fields.contains('FirstName'));
        System.assert(fields.contains('LastName'));
    }

    @IsTest
    static void nullInputValues() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead();
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(null, newContact.FirstName);
        System.assertEquals(null, newContact.LastName);
    }

    @IsTest
    static void multipleDestinations() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName'),
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'Description')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(theLead.FirstName, newContact.FirstName);
        System.assertEquals(theLead.LastName, newContact.LastName);
        System.assertEquals(theLead.FirstName, newContact.Description);
    }

    @IsTest
    static void wholeObjectTransform() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName'),
                new Transformation_Field__mdt(
                        Source_Field__c = 'FirstName',
                        Target_Field__c = 'Description',
                        Apex_Class__c = FirstNameAndLastName.class.getName(),
                        Apex_Class_Receives__c = 'Whole Object')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(theLead.FirstName, newContact.FirstName);
        System.assertEquals(theLead.LastName, newContact.LastName);
        System.assertEquals(theLead.FirstName + ' ' + theLead.LastName, newContact.Description);
    }

    @IsTest
    static void missingApexClass() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(
                        Source_Field__c = 'FirstName',
                        Target_Field__c = 'Description',
                        Apex_Class__c = 'NoSuchClassName')
        };

        try {
            new Transformation(transformationFieldMetadata, Contact.class);
        } catch (ClassNotFoundException e) {
            String message = e.getMessage();
            System.assert(message.contains('Transformation Apex Class') && message.contains('not found'), message);
            return;
        }

        System.assert(false, 'Should have thrown an exception');
    }

    @IsTest
    static void generateValues() {
        String description = 'Generated by transform';
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName'),
                new Transformation_Field__mdt(
                        Target_Field__c = 'Description',
                        Apex_Class__c = StringConstant.class.getName(),
                        Apex_Class_Parameters__c = JSON.serialize(new Map<String, Object>{'value' => description}))
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, Contact.class);

        Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
        Contact newContact = (Contact)thisTransformation.call(theLead);

        System.assertEquals(theLead.FirstName, newContact.FirstName);
        System.assertEquals(theLead.LastName, newContact.LastName);
        System.assertEquals(description, newContact.Description);
    }

    @IsTest
    static void transformSObjectToMap() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'first_name'),
                new Transformation_Field__mdt(Source_Field__c = 'Birthdate', Target_Field__c = 'date_of_birth', Apex_Class__c = 'JsonSerialize')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', Birthdate = Date.today());
        Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

        System.assertEquals(theContact.FirstName, newMap.get('first_name'));
        System.assertEquals(JSON.serialize(theContact.Birthdate), newMap.get('date_of_birth'));
    }

    @IsTest
    static void transformSObjectToMapOneOff() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'first_name'),
                new Transformation_Field__mdt(Source_Field__c = 'Birthdate', Target_Field__c = 'date_of_birth', Apex_Class__c = 'JsonSerialize')
        };

        Map<String, Object> newMap = new Map<String, Object>{
                'isMyMap' => true
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', Birthdate = Date.today());
        thisTransformation.transform(theContact, newMap);

        System.assertEquals(theContact.FirstName, newMap.get('first_name'));
        System.assertEquals(JSON.serialize(theContact.Birthdate), newMap.get('date_of_birth'));
        System.assertEquals(true, newMap.get('isMyMap'));
    }

    @IsTest
    static void sObjectToMapRoundTrip() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'first_name'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'last_name')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', LastName = 'B');
        Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

        System.assertEquals(theContact.FirstName, newMap.get('first_name'));
        System.assertEquals(theContact.LastName, newMap.get('last_name'));

        Transformation reverseTransformation = new ReverseTransformation(transformationFieldMetadata, Contact.class);

        Contact roundTripContact = (Contact)reverseTransformation.call(newMap);

        System.assertEquals(theContact.FirstName, roundTripContact.FirstName);
        System.assertEquals(theContact.LastName, roundTripContact.LastName);
    }

    @IsTest
    static void roundTripWithTransformation() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'first_name'),
                new Transformation_Field__mdt(
                        Source_Field__c = 'Birthdate',
                        Target_Field__c = 'date_of_birth',
                        Apex_Class__c = 'JsonSerialize',
                        Reverse_Apex_Class__c = DeserializeToNamedType.class.getName(),
                        Reverse_Apex_Class_Parameters__c = '{ "typeName": "Date" }')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', Birthdate = Date.today());
        Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

        System.assertEquals(theContact.FirstName, newMap.get('first_name'));
        System.assertEquals(JSON.serialize(theContact.Birthdate), newMap.get('date_of_birth'));

        Transformation reverseTransformation = new ReverseTransformation(transformationFieldMetadata, Contact.class);

        Contact roundTripContact = (Contact)reverseTransformation.call(newMap);

        System.assertEquals(theContact.FirstName, roundTripContact.FirstName);
        System.assertEquals(theContact.Birthdate, roundTripContact.Birthdate);
    }

    @IsTest
    static void transformSObjectToDeepMap() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'person.first_name'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'person.last_name')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', LastName = 'B');
        Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

        Map<String, Object> person = (Map<String, Object>)newMap.get('person');
        System.assertEquals(theContact.FirstName, person.get('first_name'));
        System.assertEquals(theContact.LastName, person.get('last_name'));
    }

    @IsTest
    static void deepSObjectToMap() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'first_name'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'last_name'),
                new Transformation_Field__mdt(Source_Field__c = 'Account.Name', Target_Field__c = 'company')
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Map<String, Object>.class);

        Contact theContact = new Contact(FirstName = 'A', LastName = 'B', Account = new Account(Name = 'ACME'));
        Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

        System.assertEquals(theContact.FirstName, newMap.get('first_name'));
        System.assertEquals(theContact.LastName, newMap.get('last_name'));
        System.assertEquals(theContact.Account.Name, newMap.get('company'));
    }

    @IsTest
    static void transformDeepMapToSObject() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'person.first_name', Target_Field__c = 'FirstName' ),
                new Transformation_Field__mdt(Source_Field__c = 'person.last_name', Target_Field__c = 'LastName' )
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata,  Lead.class);

        Map<String, Object> theMap = new Map<String, Object>{'person' => new Map<String, Object> { 'first_name' => 'A', 'last_name' => 'B'} };
        Lead newLead = (Lead)thisTransformation.call(theMap);

        Map<String, Object> person = (Map<String, Object>)theMap.get('person');
        System.assertEquals(person.get('first_name'), newLead.FirstName);
        System.assertEquals(person.get('last_name'), newLead.LastName);
    }

    @IsTest
    static void passThroughSObjectToOtherSObjectWithTargets() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'FirstName', Target_Field__c = 'FirstName'),
                new Transformation_Field__mdt(Source_Field__c = 'LastName', Target_Field__c = 'LastName')
        };

        TestIdGenerator contactIdGenerator = new TestIdGenerator(Contact.SObjectType);

        List<Contact> targetContacts = new List<Contact> {
                new Contact(Id = contactIdGenerator.next()),
                new Contact(Id = contactIdGenerator.next())
        };

        Transformation thisTransformation = new Transformation(transformationFieldMetadata, ((List<Object>)targetContacts).iterator());

        List<Lead> sourceLeads = new List<Lead> {
                new Lead(FirstName = 'A', LastName = 'B'),
                new Lead(FirstName = 'C', LastName = 'D')
        };

        List<Contact> results = new LazySObjectIterator(sourceLeads)
                .mapValues(thisTransformation)
                .toList(new List<Contact>());

        for(Integer i=0; i < targetContacts.size(); i++) {
            System.assertEquals(sourceLeads[i].FirstName, results[i].FirstName);
            System.assertEquals(sourceLeads[i].LastName, results[i].LastName);
            System.assertEquals(targetContacts[i].Id, results[i].Id);
        }
    }

    @IsTest
    static void transformationSOQLFields() {
        String exceptionMessage;

        try {
            new Transformation('Account_to_JSON', Account.class);
        } catch (SObjectException e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'No exception message expected as all fields in SOQL are present');
    }

    @IsTest
    static void reverseTransformationSOQLFields() {
        String exceptionMessage;

        try {
            new ReverseTransformation('Account_to_JSON', Account.class);
        } catch (SObjectException e) {
            exceptionMessage = e.getMessage();
        }

        System.assertEquals(null, exceptionMessage, 'No exception message expected as all fields in SOQL are present');
    }

    @IsTest static void getSourceAndTargetFields() {
        List<Transformation_Field__mdt> transformationFieldMetadata = new List<Transformation_Field__mdt> {
                new Transformation_Field__mdt(Source_Field__c = 'source1', Target_Field__c = 'target1'),
                new Transformation_Field__mdt(Source_Field__c = 'source2', Target_Field__c = 'target2')
        };

        Transformation transformation = new Transformation(transformationFieldMetadata, Contact.class);
        Set<String> sourceFields = transformation.getSourceFields();
        Set<String> targetFields = transformation.getTargetFields();

        Assert.areEqual(new Set<String>{'source1', 'source2'}, sourceFields);
        Assert.areEqual(new Set<String>{'target1', 'target2'}, targetFields);
    }

    public class FirstNameAndLastName implements Function {

        public Object call(Object o) {
            Tuple tuple = (Tuple)o;
            SObject inputSObject = (SObject)tuple.get(1);

            return inputSObject.get('FirstName') + ' ' + inputSObject.get('LastName');
        }
    }

    public class DeserializeToNamedType implements Function {

        private String typeName; // Assigned via CMDT parameters
        private Type type {
            get {
                if(type == null) {
                    type = TypeLoader.getType(typeName);
                }
                return type;
            }
            set;
        }

        public Object call(Object o) {
            return JSON.deserialize((String)o, type);
        }
    }
}