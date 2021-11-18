# Nebula Object Transformer

Transform your objects using custom metadata configuration. 

A common requirement, particularly in integrations is to be able to map instances of one type of objects into another. 
For example, we might want to map a Contact record into a JSON object represented by a map. Or we might want to do the 
reverse. Or we might need to map between SObjects, or between JSON objects. As part of the mapping, we might need to 
change the field names and/or transform the values.

This library provides a generic method to do all of that, driven by custom metadata records.

Since it is built on top of Nebula Core, it supports deep references in the field names. e.g. a field reference could be 
`Account.Name`. As a source field, this will be read correctly for an SObject or Map, as long as the data is actually 
there. Similarly, this format can be used as a target in JSON objects to implicitly constructed a nested object.   

## Installation

* Package entry
* Installation URL