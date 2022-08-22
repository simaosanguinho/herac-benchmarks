package com.array_sorting;

import java.util.HashMap;
import java.util.Map;

@SuppressWarnings("unused")
public class EntryPoint {

    public static Map<String, Object> main(Map<String, Object> args) {
        Map<String, Object> result = new HashMap<>();
        result.put("result", Workload.intersect((Integer) args.get("array_size")));
        return result;
    }
}
