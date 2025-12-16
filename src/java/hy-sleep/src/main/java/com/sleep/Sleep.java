package com.sleep;

import java.lang.InterruptedException;
import java.util.HashMap;
import java.util.Map;
import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;


@SuppressWarnings("unused")
public class Sleep {

    static Map<String, Object> output = new HashMap<>();

    static byte[] buffer;

    public static void memory(int bytes) {
        buffer = new byte[bytes];
        for (int i = 0; i < bytes; i++) {
            buffer[i] = 1;
        }
    }

    public static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException ie) {
            output.put("Log", "InterruptedException");
        }
    }

    public static Map<String, Object> main(Map<String, Object> input) {
        memory(Integer.parseInt((String)input.get("memory")));
        sleep(Long.parseLong((String)input.get("sleep")));
        return output;
    }

    public static void main(String[] args) {
        Map<String, Object> output = new HashMap<>();
        output.put("memory", "1024");
        output.put("sleep", "1000");
        output = main(output);
        System.out.println(output);
    }

    /* For c-API invocations. */
    @CEntryPoint(name = "entrypoint")
    public static void main(IsolateThread thread, CCharPointer fin, CCharPointer fout, UnsignedWord foutLen) {
        String input = CTypeConversion.toJavaString(fin);
        HashMap<String, Object> map = new HashMap<>();
        map.put("memory", "0"); // TODO - make these configurable
        map.put("sleep", "6000000"); // 100 minutes.
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
