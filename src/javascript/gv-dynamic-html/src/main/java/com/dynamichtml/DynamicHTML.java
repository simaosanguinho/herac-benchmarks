package com.dynamichtml;

import java.util.Map;

import com.oracle.svm.graalvisor.polyglot.PolyglotHostAccess;
import com.oracle.svm.graalvisor.polyglot.PolyglotEngine;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.HostAccess;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import com.github.mustachejava.DefaultMustacheFactory;
import com.fasterxml.jackson.jr.ob.JSON;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class DynamicHTML extends PolyglotHostAccess {

    private static DynamicHTMLEngine engine;
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

    /**
     * Extract arguments json encoded string into Map.
     *
     * @param jsonString json encoded String
     * @return map that illustrates json
     */
    public static Map<String, Object> jsonToMap(String jsonString) {
        try {
            if (jsonString != null && jsonString.length() > 0) {
                return JSON.std.mapFrom(jsonString);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return new HashMap<>();
    }

    // Note: Replacement for nodejs mustache package.
    @HostAccess.Export
    public String mustache(String template, String arguments) {
        Map<String, Object> scopes = jsonToMap(arguments);
        try {
            Writer writer = new StringWriter();
            new DefaultMustacheFactory().compile(new StringReader(template), "template").execute(writer, scopes);
            writer.flush();
            return writer.toString();
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }


    static class DynamicHTMLEngine extends PolyglotEngine {

        public void addBindings(String language, Context context) {
            context.getBindings(language).putMember("polyHostAccess", new DynamicHTML());
        }
    }

    private static DynamicHTMLEngine getEngine() {
        if (engine == null) {
            engine = new DynamicHTMLEngine();
        }
        return engine;
    }

    /* For Graalvisor invocation. */
    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        String url = (String) args.get("url");
        String username = (String) args.get("username");
        String nsize = (String) args.get("nsize");
        DynamicHTMLEngine engine = getEngine();
        output.put("output", engine.invoke(language, source, entrypoint, String.format("%s;%s;%s", url, username, nsize)));
        return output;
    }

    /* For standalone invocations. */
    public static void main(String[] args) {
        HashMap<String, Object> output = new HashMap<>();
        output.put("url", "http://127.0.0.1:8000/template.html");
        output.put("username", "rbruno");
        output.put("nsize", "10");
        output = main(output);
        System.out.println(output);
    }

    /* For c-API invocations. */
    @CEntryPoint(name = "entrypoint")
    public static void main(IsolateThread thread, CCharPointer fin, CCharPointer fout, UnsignedWord foutLen) {
        String input = CTypeConversion.toJavaString(fin);
        HashMap<String, Object> map = new HashMap<>();
        map.put("url", "http://127.0.0.1:8000/template.html"); // TODO - convert input into map.
        map.put("username", "rbruno");
        map.put("nsize", "10");
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
