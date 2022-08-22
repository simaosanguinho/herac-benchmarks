package com.thumbnail;

import java.util.HashMap;
import java.util.Map;

public class EntryPoint {

    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        String img = Workload.thumbnail((String) args.get("img_url"));
        output.put("result", img);
        return output;
    }
}
