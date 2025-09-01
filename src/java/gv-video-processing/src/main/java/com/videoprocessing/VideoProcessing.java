package com.videoprocessing;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import com.oracle.svm.graalvisor.utils.JsonUtils;

import java.util.HashMap;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.FileChannel;
import java.nio.channels.Channels;

public class VideoProcessing {

    public static void downloadURLIntoFile(String url, FileOutputStream fos) throws Exception {
        ReadableByteChannel readableByteChannel = Channels.newChannel(new URL(url).openStream());
        FileChannel fileChannel = fos.getChannel();
        fileChannel.transferFrom(readableByteChannel, 0, Long.MAX_VALUE);
    }

    public static void runFFmpegCommand(String[] command) {
        try {
            System.out.println(String.format("running ffmpeg command: %s", java.lang.String.join(" ", command)));
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.redirectErrorStream(true); // This merges the error stream with the standard output stream

            // Start the process
            Process process = builder.start();
            // Wait for the process to complete
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                process.getErrorStream().transferTo(System.out);
                System.out.println(String.format("FFMpeg exited with error code %s", exitCode));
            }
        } catch (IOException | InterruptedException e) {
            System.out.println(String.format("Error running ffmpeg command %s", e));
        }
    }

    private static void ffmpeg(String ffmpegPath, String fileName) throws Exception{
        String[] ffmpegCommand = new String[]{
            ffmpegPath,
            "-y",
            "-i", fileName,
            "-s", "640x480",
            "-c:a", "copy",
            fileName + "-output.mp4"
        };
        runFFmpegCommand(ffmpegCommand);
    }


    public static HashMap<String, Object> main(Map<String, Object> args) {
        String tmpDir = (String) args.get("tmpDir");
        HashMap<String, Object> output = new HashMap<>();

        String ffmpegPath = tmpDir + "/ffmpeg";
        String videoPath = tmpDir + "/video.mp4";

        if (!new File(ffmpegPath).exists()) {
            File file = new File(ffmpegPath);
            try (FileOutputStream stream = new FileOutputStream(file)) {
                downloadURLIntoFile((String)args.get("ffmpeg"), stream);
                stream.flush();
            } catch (Exception e) {
                 output.put("output", e.getMessage());
                 e.printStackTrace();
            }
            file.setWritable(false);
            file.setReadable(true);
            file.setExecutable(true);
        }

        try (FileOutputStream stream = new FileOutputStream(videoPath)) {
            downloadURLIntoFile((String)args.get("video"), stream);
            stream.flush();
        } catch (Exception e) {
             output.put("output", e.getMessage());
             e.printStackTrace();
         }

        try {
            ffmpeg(ffmpegPath, videoPath);
        } catch (Exception e) {
            output.put("output", e.getMessage());
            e.printStackTrace();
        }

        output.put("output", videoPath);
        return output;
    }

    public static void main(String[] args) {
        HashMap<String, Object> output = new HashMap<>();
        output.put("ffmpeg", "http://127.0.0.1:8000/ffmpeg");
        output.put("video", "http://127.0.0.1:8000/video.mp4");
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
