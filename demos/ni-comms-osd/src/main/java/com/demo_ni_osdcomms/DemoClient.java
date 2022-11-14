package com.demo_ni_osdcomms;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Authenticator;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Arrays;

public class DemoClient extends DemoAbstractTest {

    public void gson(int bufSize, int runs, int warmupRuns) {
        System.out.println("gson");
    }

    public void jackson(int bufSize, int runs, int warmupRuns) {
        System.out.println("jackson");
    }

    public void kryo(int bufSize, int runs, int warmupRuns) {
        System.out.println("kryo");
    }

    public void httpGet(int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];
        HttpClient client = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(1))
            .build();
        try {
            for (int i = 0; i < runs + warmupRuns; i++) {
                httpGetImpl(client, i);
                Thread.sleep(1);
            }
        } catch (InterruptedException e) {
            // nop
        }
        printResults(warmupRuns, runs);
    }

    private void httpGetImpl(HttpClient client, int i) {
        try {
            start[i] = System.nanoTime();
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:8080"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();
            client.send(request, BodyHandlers.ofString());
            stop[i] = System.nanoTime();
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    protected void printResults(int warmupRuns, int runs) {
        for (int i = 0; i < runs; i++) {
            DemoLog.log(start[warmupRuns + i], "[client]: sending #" + i);
            DemoLog.log(stop[warmupRuns + i], "[client]: sent #" + i);
        }
    }
}
