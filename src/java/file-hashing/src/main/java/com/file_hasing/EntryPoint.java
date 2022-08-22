package com.file_hasing;

import java.util.HashMap;
import java.util.Map;

@SuppressWarnings("unused")
public class EntryPoint {

    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        Workload.Result result = Workload.fileHash((String) args.get("file_url"));
        if (result != null) {
            output.put("sha1", result.getSha1());
            output.put("md5", result.getMd5());
        } else {
            output.put("sha1", null);
            output.put("md5", null);
        }
        return output;
    }
}
