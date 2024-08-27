package org.graalvm.argo.dataset.execution;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.function.Consumer;

public class NetworkUtils {

    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .connectTimeout(Duration.ofSeconds(30)).build();

    public static void sendPost(String address, String path, String contentType, byte[] content, boolean async, Consumer<String> asyncConsumer) {
        HttpRequest request = HttpRequest.newBuilder(URI.create("http://" + address + path))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", contentType)
                .header("accept", "application/json; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofByteArray(content)).build();

        if (async) {
            HTTP_CLIENT.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenAccept(asyncConsumer);
        } else {
            try {
                HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
            } catch (IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static void sendPost(String address, String path, String contentType, byte[] content, boolean async) {
        sendPost(address, path, contentType, content, async, System.out::println);
    }

}
