package com.pr;

import java.util.Map;

import com.oracle.svm.graalvisor.polyglot.PolyglotEngine;
import com.oracle.svm.graalvisor.polyglot.PolyglotHostAccess;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class PageRank extends PolyglotHostAccess {

    private static PolyglotEngine engine;
    private static String language;
    private static String source;
    private static String entrypoint;

    static {
        try {
            language = System.getProperty("com.oracle.svm.graalvisor.polyglotengine.language");
            source = Files.readString(Paths.get(System.getProperty("com.oracle.svm.graalvisor.polyglotengine.source")));
            entrypoint = System.getProperty("com.oracle.svm.graalvisor.polyglotengine.entrypoint");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static PolyglotEngine getEngine() {
        if (engine == null) {
            engine = new PolyglotEngine();
        }
        return engine;
    }

    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        PolyglotEngine engine = getEngine();
        output.put("output", engine.invoke(language, source, entrypoint, (String) args.get("size")));
        return output;
    }

    public static void main(String[] args) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("size", "100");
        System.out.println(main(map).toString());
    }

    /* For c-API invocations. */
    @CEntryPoint(name = "entrypoint")
    public static void main(IsolateThread thread, CCharPointer fin, CCharPointer fout, UnsignedWord foutLen) {
        String input = CTypeConversion.toJavaString(fin);
        HashMap<String, Object> map = new HashMap<>();
        map.put("size", "100"); // TODO - convert input into size.
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
