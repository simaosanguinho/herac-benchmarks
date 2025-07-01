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

  private static void ffmpeg(String fileName) throws Exception{
    FFmpegBuilder builder = new FFmpegBuilder()
      .setInput(fileName) // Filename, or a FFmpegProbeResult
      .overrideOutputFiles(true) // Override the output if it exists
      .addOutput("out"+fileName) // Filename for the destination
      .setFormat("mp4") // Format is inferred from filename, or can be set
      .setVideoResolution(640, 480) // at 640x480 resolution
      .setStrict(FFmpegBuilder.Strict.EXPERIMENTAL) // Allow FFmpeg to use experimental specs
      .done();
    new FFmpegExecutor(new FFmpeg("/tmp/ffmpeg")).createJob(builder).run();
  }

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        Map<String, Object> payload = inputMessage.getPayload();

        String ffmpeg = (String)payload.get("ffmpeg");
        String video = (String)payload.get("video");

        if (!new File("/tmp/ffmpeg").exists()) {
          File file = new File("/tmp/ffmpeg");
          try (FileOutputStream stream = new FileOutputStream(file)) {
            stream.write(downloadBytes(ffmpeg));
            file.setWritable(false);
            file.setReadable(true);
            file.setExecutable(true);
          }
        }

        try (FileOutputStream stream = new FileOutputStream("video.mp4")) {
          stream.write(downloadBytes(video));
        }

        ffmpeg("video.mp4");

        return "video.mp4";
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }
}
