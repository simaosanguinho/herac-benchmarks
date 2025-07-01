package functions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.messaging.Message;

import java.util.Map;
import java.util.function.Function;

@SpringBootApplication
public class CloudFunctionApplication {

  public static void main(String[] args) {
    SpringApplication.run(CloudFunctionApplication.class, args);
  }

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        Map<String, Object> payload = inputMessage.getPayload();

        String name = (String) payload.get("name");

        if (name == null) {
          name = "stranger";
        }

        return "Hello " + name + "!";
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }
}
