/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 15/11/2021
 * @description A strongly-typed constant. Deserializing from JSON won't work with nebc.Constant due to the value being
 * an Object
 */

@JsonAccess(Deserializable='always')
global class StringConstant implements nebc.Function {

    String value;

    global Object call(Object o) {
        return value;
    }
}