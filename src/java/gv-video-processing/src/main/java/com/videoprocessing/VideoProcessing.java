package com.videoprocessing;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;

import net.bramp.ffmpeg.FFmpeg;
import net.bramp.ffmpeg.FFmpegExecutor;
import net.bramp.ffmpeg.builder.FFmpegBuilder;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import com.oracle.svm.graalvisor.utils.JsonUtils;

import java.util.HashMap;

public class VideoProcessing {
    
    public static byte[] downloadBytes(String url) {
        try {
            URLConnection conn = new URL(url).openConnection();
            InputStream is = conn.getInputStream();
            byte[] bytes = is.readAllBytes();
            is.close();
            return bytes;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static void ffmpeg(String ffmpegPath, String fileName) throws Exception{
        FFmpegBuilder builder = new FFmpegBuilder()
          .setInput(fileName) // Filename, or a FFmpegProbeResult
          .overrideOutputFiles(true) // Override the output if it exists
          .addOutput(fileName + ".out") // Filename for the destination
          .setFormat("mp4") // Format is inferred from filename, or can be set
          .setVideoResolution(640, 480) // at 640x480 resolution
          .setStrict(FFmpegBuilder.Strict.EXPERIMENTAL) // Allow FFmpeg to use experimental specs
          .done();
        new FFmpegExecutor(new FFmpeg(ffmpegPath)).createJob(builder).run();
    }

    
    public static HashMap<String, Object> main(Map<String, Object> args) {
        String tmpDir = (String) args.get("tmpDir");
        HashMap<String, Object> output = new HashMap<>();

        String ffmpegPath = tmpDir + "/ffmpeg";
        String videoPath = tmpDir + "/video.mp4";
        
        if (!new File(ffmpegPath).exists()) {
            File file = new File(ffmpegPath);
            try (FileOutputStream stream = new FileOutputStream(file)) {
                stream.write(downloadBytes((String)args.get("ffmpeg")));
                file.setWritable(false);
                file.setReadable(true);
                file.setExecutable(true);
            } catch (Exception e) {
                 output.put("output", e.getMessage());
                 e.printStackTrace();
             } 
        }
        
        try (FileOutputStream stream = new FileOutputStream(videoPath)) {
            stream.write(downloadBytes((String)args.get("video")));
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
