package com.thumbnail;

import java.util.Map;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.HostAccess;

import com.oracle.svm.hydra.polyglot.PolyglotEngine;
import com.oracle.svm.hydra.polyglot.PolyglotHostAccess;
import com.oracle.svm.hydra.utils.JsonUtils;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

import ar.com.hjg.pngj.ImageInfo;
import ar.com.hjg.pngj.ImageLineInt;
import ar.com.hjg.pngj.PngReader;
import ar.com.hjg.pngj.PngWriter;

public class Thumbnail extends PolyglotHostAccess {

    private static ThumbnailEngine engine;
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
    public byte[] resize(byte[] bytes, float ratio) {
        try {
            PngReader reader = new PngReader(new ByteArrayInputStream(bytes));
            try {
                ImageInfo inputInfo = reader.imgInfo;
                int width = Math.max(1, (int) (inputInfo.cols * ratio));
                int height = Math.max(1, (int) (inputInfo.rows * ratio));
                int[][] rows = new int[inputInfo.rows][];

                for (int row = 0; row < inputInfo.rows; row++) {
                    rows[row] = ((ImageLineInt) reader.readRow(row)).getScanline().clone();
                }

                ByteArrayOutputStream output = new ByteArrayOutputStream();
                ImageInfo outputInfo = new ImageInfo(width, height, inputInfo.bitDepth, inputInfo.alpha, inputInfo.greyscale, inputInfo.indexed);
                PngWriter writer = new PngWriter(output, outputInfo);
                try {
                    for (int y = 0; y < height; y++) {
                        int srcY = Math.min(inputInfo.rows - 1, y * inputInfo.rows / height);
                        ImageLineInt outputRow = new ImageLineInt(outputInfo);
                        int[] outputScanline = outputRow.getScanline();
                        int[] inputScanline = rows[srcY];
                        for (int x = 0; x < width; x++) {
                            int srcX = Math.min(inputInfo.cols - 1, x * inputInfo.cols / width);
                            int srcOffset = srcX * inputInfo.channels;
                            int dstOffset = x * outputInfo.channels;
                            System.arraycopy(inputScanline, srcOffset, outputScanline, dstOffset, inputInfo.channels);
                        }
                        writer.writeRow(outputRow, y);
                    }
                } finally {
                    writer.end();
                }

                return output.toByteArray();
            } finally {
                reader.close();
            }
        } catch (Throwable e) {
            e.printStackTrace();
            throw new IllegalStateException("Thumbnail resize failed", e);
        }
    }

    static class ThumbnailEngine extends PolyglotEngine {

        public void addBindings(String language, Context context) {
            context.getBindings(language).putMember("polyHostAccess", new Thumbnail());
        }
    }

    private static ThumbnailEngine getEngine() {
        if (engine == null) {
            engine = new ThumbnailEngine();
        }
        return engine;
    }

    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();
        String url = (String) args.get("url");
        String tmpDir = (String) args.get("tmpDir");
        ThumbnailEngine engine = getEngine();
        output.put("output", engine.invoke(language, source, entrypoint, String.format("%s;%s", url, tmpDir)));
        return output;
    }

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
