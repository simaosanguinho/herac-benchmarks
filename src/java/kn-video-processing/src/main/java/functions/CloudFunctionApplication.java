package functions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.messaging.Message;

import java.util.function.Function;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;
import java.util.HashMap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import net.bramp.ffmpeg.FFmpeg;
import net.bramp.ffmpeg.FFmpegExecutor;
import net.bramp.ffmpeg.builder.FFmpegBuilder;

@SpringBootApplication
public class CloudFunctionApplication {

  public static void main(String[] args) {
    SpringApplication.run(CloudFunctionApplication.class, args);
  }

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

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        long threadId = Thread.currentThread().getId();
        String tmpDir = "/tmp/sandbox-" + threadId;
        initTmpDirectory(tmpDir);

        String ffmpegPath = tmpDir + "/ffmpeg";
        String videoPath = tmpDir + "/video.mp4";

        Map<String, Object> payload = inputMessage.getPayload();

        String ffmpeg = (String)payload.get("ffmpeg");
        String video = (String)payload.get("video");

        if (!new File(ffmpegPath).exists()) {
          File file = new File(ffmpegPath);
          try (FileOutputStream stream = new FileOutputStream(file)) {
            stream.write(downloadBytes(ffmpeg));
            file.setWritable(false);
            file.setReadable(true);
            file.setExecutable(true);
          }
        }

        try (FileOutputStream stream = new FileOutputStream(videoPath)) {
          stream.write(downloadBytes(video));
        }

        ffmpeg(ffmpegPath, videoPath);

        return videoPath;
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }

  public static void initTmpDirectory(String directoryPath) {
    Path path = Paths.get(directoryPath);
    if (Files.notExists(path)) {
      try {
        Files.createDirectories(path);
      } catch (IOException e) {
        System.err.println(String.format("[thread %d] Error creating %s directory: %s", Thread.currentThread().getId(), directoryPath, e.getMessage()));
      }
    }
  }
}
