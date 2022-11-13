package com.demo_ni_comms;

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

    public void openSocket(int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];
        try {
            for (int i = 0; i < runs + warmupRuns; i++) {
                openSocketImpl(i);
                Thread.sleep(1);
            }
        } catch (InterruptedException e) {
            // nop
        }
        printResults(warmupRuns, runs);
    }

    private void openSocketImpl(int i) {
        start[i] = System.nanoTime();
        try (Socket socket = new Socket("localhost", DemoServer.PORT)) {
            stop[i] = System.nanoTime();
            // socket.getOutputStream().write(0);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
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

    protected void tcpCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];

        byte[] bytes = new byte[size];
        Arrays.fill(bytes, (byte)'x');

        DemoLog.log(String.format("[client]: connecting to localhost:%d...", DemoServer.PORT));    
        try (Socket socket = new Socket("localhost", DemoServer.PORT)) {
            // socket.setTcpNoDelay(true);
            try (OutputStream out = new BufferedOutputStream(socket.getOutputStream(), bufSize == 0 ? size : bufSize)) {
                for (int i = 0; i < runs + warmupRuns; i++) {
                    tcpCommsTestSendData(out, bytes, i, size);
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        printResults(warmupRuns, runs);
    }

    private void tcpCommsTestSendData(OutputStream out, byte[] bytes, int i, int size) throws IOException {
        start[i] = System.nanoTime();
        out.write(bytes);
        stop[i] = System.nanoTime();
    }

    protected void udpCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];

        try (DatagramSocket socket = new DatagramSocket()) {
            byte[] bytes = new byte[size];
            Arrays.fill(bytes, (byte)'x');
            DatagramPacket datagram = new DatagramPacket(bytes, size, new InetSocketAddress("localhost", DemoServer.PORT));

            for (int i = 0; i < runs + warmupRuns; i++) {
                udpCommsTestRecvData(socket, datagram, i);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        printResults(warmupRuns, runs);
    }

    private void udpCommsTestRecvData(DatagramSocket socket, DatagramPacket datagram, int i) throws IOException {
        start[i] = System.nanoTime();
        socket.send(datagram);
        stop[i] = System.nanoTime();
    }

    protected void printResults(int warmupRuns, int runs) {
        for (int i = 0; i < runs; i++) {
            DemoLog.log(start[warmupRuns + i], "[client]: sending #" + i);
            DemoLog.log(stop[warmupRuns + i], "[client]: sent #" + i);
        }
    }
}
