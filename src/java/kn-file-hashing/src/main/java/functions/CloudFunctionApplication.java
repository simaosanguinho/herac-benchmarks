package functions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.messaging.Message;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.math.BigInteger;
import java.util.Map;
import java.util.function.Function;

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

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        Map<String, Object> payload = inputMessage.getPayload();

        byte[] bytes = downloadBytes((String) payload.get("url"));
        String result = String.format("%032X", new BigInteger(1, MessageDigest.getInstance("MD5").digest(bytes)));

        return result;
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }
}
