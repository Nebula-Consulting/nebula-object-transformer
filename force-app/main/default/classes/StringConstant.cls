/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 15/11/2021
 * @description (if required)
 */

@JsonAccess(Deserializable='always')
global class StringConstant implements nebc.Function {

    String value;

    global Object call(Object o) {
        return value;
    }
}