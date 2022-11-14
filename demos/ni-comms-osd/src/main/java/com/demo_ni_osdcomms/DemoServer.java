package com.demo_ni_osdcomms;

import java.io.BufferedInputStream;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.net.Authenticator;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.http.HttpClient;
import java.time.Duration;

public class DemoServer extends DemoAbstractTest {

    public static int PORT = 12345;

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
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            for (int i = 0; i < runs + warmupRuns; i++) {
                httpGetImpl(serverSocket, i);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        printResults(warmupRuns, runs);
    }

    private void httpGetImpl(ServerSocket server, int i) {
        // try {
        //     String response = 
        //         "HTTP/1.1 200 OK\r\n" +
        //         "Content-Length: 88\r\n" +
        //         "Content-Type: text/html\r\n" +
        //         "\r\n" +
        //         "<html>\r\n" +
        //         "<body>\r\n" +
        //         "<h1>Hello, World!</h1>\r\n" +
        //         "</body>\r\n" +
        //         "</html>\r\n"
        //         ;
        //     start[i] = System.nanoTime();
        //     Socket client = server.accept();
        //     System.err.println("Accepted");
        //     client.getInputStream().readAllBytes();
        //     try (BufferedWriter w = new BufferedWriter(new OutputStreamWriter(client.getOutputStream()))) {
        //         w.write(response);
        //         w.flush();
        //     }
        //     stop[i] = System.nanoTime();
        //     // client.setTcpNoDelay(true);
        //     // int n = client.getInputStream().read();
        // } catch (IOException e) {
        //     throw new RuntimeException(e);
        // }
    }

    protected void printResults(int warmupRuns, int runs) {
        for (int i = 0; i < runs; i++) {
            DemoLog.log(start[warmupRuns + i], "[server]: receiving #" + i);
            DemoLog.log(stop[warmupRuns + i], "[server]: received #" + i);
        }
    }
}
