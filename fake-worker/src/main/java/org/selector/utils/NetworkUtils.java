package org.selector.utils;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

public class NetworkUtils {

    private static final Map<String, HttpClient> CLIENTS = new HashMap<>();

    public static void sendPost(String address, String path, String contentType, byte[] content, boolean async, Consumer<String> asyncConsumer) {
        HttpRequest request = HttpRequest.newBuilder(URI.create("http://" + address + path))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", contentType)
                .header("accept", "text/plain; charset=UTF-8")
                .header("X-Sleep-Duration", "200")
                .POST(HttpRequest.BodyPublishers.ofByteArray(content)).build();

        HttpClient client = getClient(path);
        if (async) {
            client.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenAccept(asyncConsumer);
        } else {
            try {
                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                System.out.println(response.body());
            } catch (IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static void sendPost(String address, String path, String contentType, byte[] content, boolean async) {
        sendPost(address, path, contentType, content, async, new InvocationCallback());
    }

    private static HttpClient getClient(String path) {
        CLIENTS.computeIfAbsent(path, k -> HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(30)).build());
        return CLIENTS.get(path);
    }

    private static class InvocationCallback implements Consumer<String> {
        private final long beginTimestamp;

        private InvocationCallback() {
            this.beginTimestamp = System.currentTimeMillis();
        }

        @Override
        public void accept(String s) {
            System.out.println("Time took: " + (System.currentTimeMillis() - beginTimestamp));
        }
    }

}
