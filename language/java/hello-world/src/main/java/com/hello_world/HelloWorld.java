package com.hello_world;
import com.google.gson.*;

public class HelloWorld {

    public static JsonObject main(JsonObject input) {
        input.addProperty("Log","Hello World");
        input.addProperty("VM Context",System.getProperty("java.vm.name"));
        return input;
    }

    public static void main(String[] args){
        System.out.println(main(new JsonObject()));
    }
}
