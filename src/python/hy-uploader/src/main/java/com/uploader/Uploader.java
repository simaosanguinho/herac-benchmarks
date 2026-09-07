package com.uploader;

import java.util.Map;

import com.oracle.svm.hydra.polyglot.PolyglotEngine;
import com.oracle.svm.hydra.polyglot.PolyglotHostAccess;
import com.oracle.svm.hydra.utils.JsonUtils;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.HostAccess;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class Uploader extends PolyglotHostAccess {

    private static PolyglotEngine engine;
    private static String language;
    private static String source;
    private static String entrypoint;

    static {
        try {
            language = System.getProperty("com.oracle.svm.hydra.polyglotengine.language");
            source = Files.readString(Paths.get(System.getProperty("com.oracle.svm.hydra.polyglotengine.source")));
            entrypoint = System.getProperty("com.oracle.svm.hydra.polyglotengine.entrypoint");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @HostAccess.Export
    public byte[] downloadBytes(String url) {
        return super.downloadBytes(url);
    }

    @HostAccess.Export
    public void uploadBytes(String url, byte[] bytes) {
        super.uploadBytes(url, bytes);
    }

    static class UploaderEngine extends PolyglotEngine {

        public void addBindings(String language, Context context) {
            context.getBindings(language).putMember("polyHostAccess", new Uploader());
        }
    }

    private static PolyglotEngine getEngine() {
        if (engine == null) {
            engine = new UploaderEngine();
        }
        return engine;
    }

    /* For Hydra invocation. */
    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        PolyglotEngine engine = getEngine();
        String downloadUrl = (String) args.get("download_url");
        String uploadUrl = (String) args.get("upload_url");
        output.put("output", engine.invoke(language, source, entrypoint, String.format("%s;%s", downloadUrl, uploadUrl)));
        return output;
    }

    /* For standalone invocations. */
    public static void main(String[] args) {
        HashMap<String, Object> output = new HashMap<>();
        output.put("download_url", "http://127.0.0.1:8000/new.mp4");
        output.put("upload_url", "http://127.0.0.1:9696/upload");
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
