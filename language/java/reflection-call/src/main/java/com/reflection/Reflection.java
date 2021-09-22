package com.reflection;

import java.util.HashMap;
import java.util.Map;

@SuppressWarnings("unused")
public class Reflection {

    public static Map<String, Object> main(Map<String, Object> args) {
        String response = "Success";
        String className = (String) args.get("argument");
        try {
            Class.forName(className);
        } catch (ClassNotFoundException e) {
            response = "Failed";
        }
        Map<String, Object> res = new HashMap<>();
        res.put("response", response);
        return res;
    }

}

@SuppressWarnings("unused")
class DummyClass {
}
