# Nebula Object Transformer

Transform your objects! Configure your transformations using custom metadata records. 

A common requirement, particularly in integrations is to be able to transform instances of one type of objects into another. 
For example, we might want to transform a Contact record into a JSON object represented by a map. Or we might want to do the 
reverse. Or we might need to transform between SObjects, or between JSON objects. As part of the transformation, we might need to 
change the field names and/or apply functions to the values.

This library provides a generic method to do all of that, driven by custom metadata records.

Since it is built on top of [Nebula Core](https://github.com/aidan-harding/nebula-core), it supports deep references in 
the field names. e.g. a field reference on Contact could be 
`Account.Name`. As a source field, this will be read correctly for an SObject or Map, as long as the data is actually 
there. Similarly, this format can be used as a target in JSON objects to implicitly construct a nested object.   

## Installation

* Package entry `"Nebula Object Transformer": "04t6M000000kmOgQAI"`
* Installation URL `/packaging/installPackage.apexp?p0=04t6M000000kmOgQAI`

## Examples

The following examples are based on [TransformationTest](force-app/main/default/classes/TransformationTest.cls). In 
the package tests, custom metadata records are created in memory before running the transformation. The examples below are more like 
real-world usage where the custom metadata is queried by name. 

The examples below show the custom metadata records in tabular format. Note that the custom metadata records in the 
tables are not part of the package. You would create your own custom metadata for your own requirements.   

### Lead to Contact

Custom Metadata (Lead_to_Contact):

| Source Field | Target Field |
|--------------|--------------|
| FirstName    | FirstName    |
| LastName     | LastName     | 

Code:

    nebc.Transformation thisTransformation = new nebc.Transformation('Lead_to_Contact', Contact.class);

    Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
    Contact newContact = (Contact) thisTransformation.call(theLead);

    System.assertEquals(theLead.FirstName, newContact.FirstName);
    System.assertEquals(theLead.LastName, newContact.LastName);

In this example, input and output are similar (both SObjects) and they don't require any transformation on the values. 
Source values are copied to the target for each field. The `Type` passed to the Transformation constructor allows the resulting
SObject to be created correctly.

### Null input values are fine

As you would hope, null values on the input record are no problem. So, we can repeat the same transformation, with 
an empty Lead. 

    nebc.Transformation thisTransformation = new nebc.Transformation('Lead_to_Contact', Contact.class);
    
    Lead theLead = new Lead();
    Contact newContact = (Contact) thisTransformation.call(theLead);
    
    System.assertEquals(null, newContact.FirstName);
    System.assertEquals(null, newContact.LastName);

### Same field, multiple destinations

It's also fine to send the same input field to multiple field in the output object.

Custom Metadata (Lead_to_Contact_Description):

| Source Field | Target Field |
|--------------|--------------|
| FirstName    | FirstName    |
| LastName     | LastName     | 
| FirstName    | Description  | 

    nebc.Transformation thisTransformation = new nebc.Transformation('Lead_to_Contact_Description', Contact.class);

    Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
    Contact newContact = (Contact) thisTransformation.call(theLead);

    System.assertEquals(theLead.FirstName, newContact.FirstName);
    System.assertEquals(theLead.LastName, newContact.LastName);
    System.assertEquals(theLead.FirstName, newContact.Description);


### Contact to JSON

When the output type should be a JSON object, this is achieved by specifying `Map<String, Object>.class` in the constructor of
`nebc.Transformation`. In this example, we transform a Contact to JSON object.

Custom Metadata (Contact_to_JSON):

| Source Field | Target Field | 
|--------------|--------------|
| FirstName    | first_name   |
| LastName     | last_name    | 

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_to_JSON', Map<String, Object>.class);

    Contact theContact = new Contact(FirstName = 'A', LastName = 'b');
    Map<String, Object> newMap = (Map<String, Object>) thisTransformation.call(theContact);

    System.assertEquals(theContact.FirstName, newMap.get('first_name'));
    System.assertEquals(theContact.LastNamne, newMap.get('last_name'));

### Contact with relationship field to JSON

When the input is an SObject, and there are lookup fields, we can use deep references to read from them. Note that 
extra data is never queried, so you must make sure that you have all the required fields yourself (see [How to query for transformation](#how-to-query-for-transformation))  

Custom Metadata (Contact_deep_to_JSON):

| Source Field | Target Field | 
|--------------|--------------|
| FirstName    | first_name   |
| LastName     | last_name    | 
| Account.Name | company      | 

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_deep_to_JSON',  Map<String, Object>.class);

    Contact theContact = new Contact(FirstName = 'A', LastName = 'B', Account = new Account(Name = 'ACME'));
    Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

    System.assertEquals(theContact.FirstName, newMap.get('first_name'));
    System.assertEquals(theContact.LastName, newMap.get('last_name'));
    System.assertEquals(theContact.Account.Name, newMap.get('company'));

### Transformation functions

When some values need to be modified during the transformation, we can provide the name of an Apex class to perform 
the transformation. In this example, we are taking a Date from Contact and transforming it into a String that can be used in JSON:

Custom Metadata (Contact_to_JSON_transform):

| Source Field | Target Field  | Apex Class         |
|--------------|---------------|--------------------|
| FirstName    | first_name    |
| LastName     | last_name     |
| Birthdate    | date_of_birth | nebc.JsonSerialize |

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_to_JSON_transform', Map<String, Object>.class);

    Contact theContact = new Contact(FirstName = 'A', LastName = 'B', Birthdate = Date.today());
    Map<String, Object> newMap = (Map<String, Object>) thisTransformation.call(theContact);

    System.assertEquals(theContact.FirstName, newMap.get('first_name'));
    System.assertEquals(theContact.LastNamne, newMap.get('last_name'));
    System.assertEquals(JSON.serialize(theContact.Birthdate), newMap.get('date_of_birth'));

The transformation function we needed already exists in Nebula Core, but you can always write your own class. It just 
has to implement `nebc.Function` and be global. It should expect to receive an Object which is the value from the input 
field. 

### Contact to JSON with deep maps

By using dots in the target fields, we can construct a map with sub-objects inside it.

Custom Metadata (Contact_to_JSON_deep):

| Source Field | Target Field      |
|--------------|-------------------|
| FirstName    | person.first_name |
| LastName     | person.last_name  |

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_to_JSON_deep', Map<String, Object>.class);
    
    Contact theContact = new Contact(FirstName = 'A', LastName = 'B');
    Map<String, Object> newMap = (Map<String, Object>) thisTransformation.call(theContact);
    
    Map<String, Object> person = (Map<String, Object>) newMap.get('person');
    System.assertEquals(theContact.FirstName, person.get('first_name'));
    System.assertEquals(theContact.LastName, person.get('last_name'));

### Deep map to Lead

Similarly, a JSON object with nested objects can be read directly as input for a transformation.

Custom Metadata (JSON_to_Lead_deep):

| Source Field      | Target Field | 
|-------------------|--------------|
| person.first_name | FirstName    |
| person.last_name  | LastName     |

    nebc.Transformation thisTransformation = new nebc.Transformation('JSON_to_Lead_deep', Lead.class);

    Map<String, Object> theMap = new Map<String, Object>{
            'person' => new Map<String, Object>{
                    'first_name' => 'A', 'last_name' => 'B'
            }
    };
    Lead newLead = (Lead) thisTransformation.call(theMap);

    Map<String, Object> person = (Map<String, Object>) theMap.get('person');
    System.assertEquals(person.get('first_name'), newLead.FirstName);
    System.assertEquals(person.get('last_name'), newLead.LastName);

### Constants in the metadata

By using a constant transformation function, we can set constant values in the metadata. 
More direct support for constants could be useful in a future version. 

Custom Metadata (Lead_to_Contact_generate):

| Source Field | Target Field | Apex Class          | Apex Class Parameters                |
|--------------|--------------|---------------------|--------------------------------------|
| FirstName    | FirstName    |                     |                                      |
| LastName     | LastName     |                     |                                      |
|              | Description  | nebc.StringConstant | `{ "value": "a metadata constant!"}` |

    Transformation thisTransformation = new Transformation('Lead_to_Contact_generate', Contact.class);

    Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
    Contact newContact = (Contact)thisTransformation.call(theLead);

    System.assertEquals(theLead.FirstName, newContact.FirstName);
    System.assertEquals(theLead.LastName, newContact.LastName);
    System.assertEquals('a metadata constant!', newContact.Description);

### Whole-object transformation functions TBD

Sometimes the function to modify values during the transformation might need the whole input object to calculate an 
output value e.g. for concatenating two text/string fields into one, or for doing a calculation. In that case, you can 
set the "Apex Class Receives" Parameter in the custom metadata. In this example, we concatenate the first and last name 
into the description field. 

Custom Metadata (Lead_to_Contact_whole_object):

| Source Field | Target Field | Apex Class           | Apex Class Receives |
|--------------|--------------|----------------------|---------------------|
| FirstName    | FirstName    |
| LastName     | LastName     |
| FirstName    | Description  | FirstNameAndLastName | Whole Object        |

    nebc.Transformation thisTransformation = new nebc.Transformation('Lead_to_Contact_whole_object', Contact.class);

    Lead theLead = new Lead(FirstName = 'A', LastName = 'B');
    Contact newContact = (Contact)thisTransformation.call(theLead);

    System.assertEquals(theLead.FirstName, newContact.FirstName);
    System.assertEquals(theLead.LastName, newContact.LastName);
    System.assertEquals(theLead.FirstName + ' ' + theLead.LastName, newContact.Description);

In this case, the Apex Class will receive a `nebc.Tuple` containing the metadata for this field, and the whole input 
object i.e. <nebc__Transformation_Field__mdt, Lead>. So, the implementation of `FirstNameAndLastName` is as follows

    global class FirstNameAndLastName implements nebc.Function {

        public Object call(Object o) {
            nebc.Tuple tuple = (nebc.Tuple)o;
            SObject inputSObject = (SObject)tuple.get(1);

            return inputSObject.get('FirstName') + ' ' + inputSObject.get('LastName');
        }
    }


### Reverse transformations

You can easily create a reverse transformation using the same metadata as for the forwards transformation. So, we can 
re-use the metadata from [Contact to JSON](#contact-to-json) to do a round-trip

Custom Metadata (Contact_to_JSON):

| Source Field | Target Field | 
|--------------|--------------|
| FirstName    | first_name   |
| LastName     | last_name    | 

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_to_JSON',  Map<String, Object>.class);

    Contact theContact = new Contact(FirstName = 'A', Birthdate = Date.today());
    Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

    System.assertEquals(theContact.FirstName, newMap.get('first_name'));
    System.assertEquals(theContact.LastName, newMap.get('last_name'));

    nebc.Transformation reverseTransformation = new nebc.ReverseTransformation('Contact_to_JSON', Contact.class);

    Contact roundTripContact = (Contact)reverseTransformation.call(newMap);

    System.assertEquals(theContact.FirstName, roundTripContact.FirstName);
    System.assertEquals(theContact.LastName, roundTripContact.LastName);

This offers the same functionality as a forward transformation. It simply swaps some metadata fields around in the 
constructor.

### Reverse transformation with transformation function

To reverse a transformation where you provided an Apex Class to transform the data, you may need to provide a 
Reverse Apex Class in the custom metadata. For example, we can do a round trip on [Transformation functions](#transformation-functions)
from earlier.

Custom Metadata (Contact_to_JSON_transform_reversible):

| Source Field | Target Field  | Apex Class         | Reverse Apex Class     | Reverse Apex Class Parameters |
|--------------|---------------|--------------------|------------------------|-------------------------------|
| FirstName    | first_name    |
| LastName     | last_name     |
| Birthdate    | date_of_birth | nebc.JsonSerialize | DeserializeToNamedType | `{ "typeName": "Date" }`      |


    nebc.Transformation thisTransformation = new nebc.Transformation(transformationFieldMetadata,  Map<String, Object>.class);

    Contact theContact = new Contact(FirstName = 'A', Birthdate = Date.today());
    Map<String, Object> newMap = (Map<String, Object>)thisTransformation.call(theContact);

    System.assertEquals(theContact.FirstName, newMap.get('first_name'));
    System.assertEquals(JSON.serialize(theContact.Birthdate), newMap.get('date_of_birth'));

    nebc.Transformation reverseTransformation = new nebc.ReverseTransformation(transformationFieldMetadata, Contact.class);

    Contact roundTripContact = (Contact)reverseTransformation.call(newMap);

    System.assertEquals(theContact.FirstName, roundTripContact.FirstName);
    System.assertEquals(theContact.Birthdate, roundTripContact.Birthdate);

Where the actual transformation function is defined as:

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


## How to query for transformation

When the source record is an SObject, it is useful to know which fields need to be queried. Once a `nebc.Transformation` 
instance is initialised, you can get the field list using `getSourceFields()` e.g.

Custom Metadata (Contact_deep_to_JSON):

| Source Field | Target Field | 
|--------------|--------------|
| FirstName    | first_name   |
| LastName     | last_name    | 
| Account.Name | company      | 

    nebc.Transformation thisTransformation = new nebc.Transformation('Contact_deep_to_JSON',  Map<String, Object>.class);

    Set<String> fields = thisTransformation.getSourceFields();
    System.assertEquals(3, fields.size());
    System.assert(fields.contains('FirstName'));
    System.assert(fields.contains('LastName'));
    System.assert(fields.contains('Account.Name'));

If you're familiar with Nebula Core, you can use `nebc.QueryBuilder` to generate a query e.g.

    String query = new nebc.QueryBuilder(Contact.SObjectType)
            .addFields(fields)
            .setWhereClause('Id = :anId')
            .getQuery();