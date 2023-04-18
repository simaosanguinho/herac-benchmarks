package com.genericapp;

import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class GenericApp {

    static Map<String, Object> output = new HashMap<>();

    static byte[] buffer;

    public static String genericStuff(int bytes, int duration) throws Exception {
        buffer = new byte[bytes];
        long start = System.currentTimeMillis();
        Random rand = new Random();
        String result = "";

        while (System.currentTimeMillis() < (start + duration)) {
            // This simulates going over the network to getch some data.
            Thread.sleep(100);
            rand.nextBytes(buffer);
            result = new String(MessageDigest.getInstance("MD5").digest(buffer));
        }
        return result;
    }

    public static Map<String, Object> main(Map<String, Object> input) throws Exception {
        genericStuff(Integer.parseInt((String)input.get("memory")), Integer.parseInt((String)input.get("duration")));
        return output;
    }

    public static void main(String[] args) throws Exception {
        Map<String, Object> input = new HashMap<>();
        // Memory in bytes.
        input.put("memory", args[0]);
        // Duration in milliseconds.
        input.put("duration", args[1]);
        main(input);
    }
}