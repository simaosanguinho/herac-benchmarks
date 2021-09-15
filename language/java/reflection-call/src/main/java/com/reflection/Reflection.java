package com.reflection;

import com.google.gson.JsonObject;

public class Reflection {

    public static JsonObject main(JsonObject args){
        String response = "Success";
        String className = args.get("argument").getAsString();
        System.out.println(className);
        try {
            Class.forName(className);
        } catch (ClassNotFoundException e) {
            response = "Failed";
        }
        JsonObject res = new JsonObject();
        res.addProperty("response",response);
        return res;
    }


}

class DummyClass {
}
