package com.httprequest;

import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;
import java.util.HashMap;
import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import com.oracle.svm.hydra.utils.JsonUtils;

public class HttpRequest {

    public static byte[] downloadBytes(String url) {
        try {
            return downloadBytesInternal(url);
        } catch (Exception e) {
            e.printStackTrace();
            return e.getMessage().getBytes();
        }
    }

    public static byte[] downloadBytesInternal(String url) throws Exception {
        URLConnection conn = new URL(url).openConnection();
        try (InputStream is = conn.getInputStream()) {
            return is.readAllBytes();
        }
    }

    /* For Hydra invocation. */
    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        output.put("size", downloadBytes((String)args.get("url")).length);
        return output;
    }

    /* For standalone invocations. */
    public static void main(String[] args) {
        HashMap<String, Object> output = new HashMap<>();
        output.put("url", "http://127.0.0.1:8000/snap.png");
        output.put("tmpDir", "/tmp");
        output = main(output);
        System.out.println(output);
    }

    /* For c-API invocations. */
    @CEntryPoint(name = "entrypoint")
    public static void main(IsolateThread thread, CCharPointer fin, CCharPointer fout, UnsignedWord foutLen) {
        String input = CTypeConversion.toJavaString(fin);
        Map<String, Object> map = JsonUtils.jsonToMap(input);
        String output = main(map).toString();
        if (foutLen.rawValue() > 0) {
            if (output.length() > (int) foutLen.rawValue()) {
                CTypeConversion.toCString(output.substring(0, (int) foutLen.rawValue() - 1), fout, foutLen);
            } else {
                CTypeConversion.toCString(output, fout, foutLen);
            }
        }
    }
}
