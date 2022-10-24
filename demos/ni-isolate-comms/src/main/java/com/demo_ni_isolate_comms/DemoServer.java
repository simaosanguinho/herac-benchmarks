package com.demo_ni_isolate_comms;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;

public class DemoServer {

    public static int PORT = 12345;

    public void network128B(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network256B(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network512B(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network1KB(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network1MB(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network10MB(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    public void network100MB(int runs, int warmupRuns) {
        networkCommsTest(runs, warmupRuns);
    }

    private void networkCommsTest(int runs, int warmupRuns) {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            DemoLog.log(String.format("%s started on port %d, waiting for client...", this.getClass().getName(), PORT));
            Socket client = serverSocket.accept();
            try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()))) {
                try {
                    for (int i = 0; i < runs; i++) {
                        DemoLog.log("[server]: receiving #" + i);
                        String received = in.readLine();
                        DemoLog.log("[server]: received #" + i);
                        assert received != null;
                    }
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

}
