package functions;

import java.util.function.Function;
import java.util.concurrent.ThreadLocalRandom;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.Map;
import javax.imageio.ImageIO;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.messaging.Message;

@SpringBootApplication
public class CloudFunctionApplication {

  public static InceptionImageClassifier classifier = null;
  public static String TMP_IMG_PATH = String.format("/tmp/img-%d.jpg", ThreadLocalRandom.current().nextInt(0, 1024 + 1));

  public static void main(String[] args) {
    SpringApplication.run(CloudFunctionApplication.class, args);
  }

  public static byte[] fromInputStream(InputStream is) throws Exception {
    ByteArrayOutputStream buffer = new ByteArrayOutputStream();
    int nRead;
    byte[] data = new byte[16384];

    while ((nRead = is.read(data, 0, data.length)) != -1) {
      buffer.write(data, 0, nRead);
    }

    return buffer.toByteArray();
  }

  public static byte[] downloadBytes(String url) {
    try {
      URLConnection conn = new URL(url).openConnection();
      InputStream is = conn.getInputStream();
      byte[] bytes = fromInputStream(is); 
      is.close();
      return bytes;
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }
    
  public static void downloadIfNecessary(String fileName, String fileURL) throws FileNotFoundException, IOException {
  	if (!new File(fileName).exists()) {
      File file = new File(fileName);
      try (FileOutputStream stream = new FileOutputStream(file)) {
        stream.write(downloadBytes(fileURL));
        file.setWritable(false);
        file.setReadable(true);
        file.setExecutable(true);
      } 
    }
  }

  public static String process(String modelUrl, String labelsUrl, String imageUrl) throws Exception {
    if (classifier == null) {
      classifier = new InceptionImageClassifier();
      downloadIfNecessary("/tmp/tensorflow_inception_graph.pb", modelUrl);
      downloadIfNecessary("/tmp/imagenet_comp_graph_label_strings.txt", labelsUrl);
    	classifier.load_model(new FileInputStream("/tmp/tensorflow_inception_graph.pb"));
    	classifier.load_labels(new FileInputStream(("/tmp/imagenet_comp_graph_label_strings.txt")));
    }

    try (FileOutputStream stream = new FileOutputStream(TMP_IMG_PATH)) {
      stream.write(downloadBytes(imageUrl));
    }

    return classifier.predict_image(ImageIO.read(new FileInputStream(TMP_IMG_PATH)));
  }

  @Bean
  public Function<Message<Map<String, Object>>, String> echo() {
    return (inputMessage) -> {
      try {
        Map<String, Object> payload = inputMessage.getPayload();

        String modelUrl = (String) payload.get("model_url");
        String labelsUrl = (String) payload.get("labels_url");
        String imageUrl = (String) payload.get("image_url");

        String result = process(modelUrl, labelsUrl, imageUrl);

        return result;
      } catch (Exception e) {
        e.printStackTrace();
        return e.getMessage();
      }
    };
  }
}
