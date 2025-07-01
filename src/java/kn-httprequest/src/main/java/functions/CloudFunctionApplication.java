package functions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.messaging.Message;

import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;
import java.util.function.Function;

@SpringBootApplication
public class CloudFunctionApplication {

  public static void main(String[] args) {
    SpringApplication.run(CloudFunctionApplication.class, args);
  }

  public static byte[] downloadBytes(String url) throws Exception {
    URLConnection conn = new URL(url).openConnection();
    try (InputStream is = conn.getInputStream()) {
        return is.readAllBytes();
    }
  }

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        Map<String, Object> payload = inputMessage.getPayload();

        byte[] bytes = downloadBytes((String) payload.get("url"));

        return String.valueOf(bytes.length);
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }
}
