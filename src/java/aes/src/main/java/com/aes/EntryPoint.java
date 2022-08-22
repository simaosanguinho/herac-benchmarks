package com.aes;

import java.util.HashMap;
import java.util.Map;

import static java.nio.charset.StandardCharsets.UTF_8;

@SuppressWarnings("unused")
public class EntryPoint {

    public static Map<String, Object> main(Map<String, Object> args) throws Exception {
        Map<String, Object> output = new HashMap<>();
        String message = (String) args.get("message");
        String password = (String) args.get("password");

        if (args.get("type") == "encrypt") {
            output.put("result", Workload.encrypt(message.getBytes(UTF_8), password));
        } else {
            if (args.get("type") == "decrypt") {
                output.put("result", Workload.decrypt(message, password));
            } else {
                output.put("result", "Wrong selection! Possible: encrypt or decrypt!");
            }
        }
        return output;
    }
}
