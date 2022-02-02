/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 21/01/2022
 * @description Constructed with a Type, returns an never-ending sequence of new instances of that type
 */

public class NewInstanceGenerator implements Iterator<Object> {

    private Type typeToCreate;

    public NewInstanceGenerator(Type typeToCreate) {
        this.typeToCreate = typeToCreate;
    }

    public Boolean hasNext() {
        return true;
    }

    public Object next() {
        return typeToCreate.newInstance();
    }
}