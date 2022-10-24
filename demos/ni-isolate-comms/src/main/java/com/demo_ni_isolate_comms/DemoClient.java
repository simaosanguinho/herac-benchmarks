package com.demo_ni_isolate_comms;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.util.Arrays;

public class DemoClient {

    public void network128B(int runs, int warmupRuns) {
        networkCommsTest(128, runs, warmupRuns);
    }

    public void network256B(int runs, int warmupRuns) {
        networkCommsTest(256, runs, warmupRuns);
    }

    public void network512B(int runs, int warmupRuns) {
        networkCommsTest(512, runs, warmupRuns);
    }

    public void network1KB(int runs, int warmupRuns) {
        networkCommsTest(1024, runs, warmupRuns);
    }

    public void network1MB(int runs, int warmupRuns) {
        networkCommsTest(1024*1024, runs, warmupRuns);
    }

    public void network10MB(int runs, int warmupRuns) {
        networkCommsTest(10*1024*1024, runs, warmupRuns);
    }

    public void network100MB(int runs, int warmupRuns) {
        networkCommsTest(100*1024*1024, runs, warmupRuns);
    }

    private void networkCommsTest(int size, int runs, int warmupRuns) {
        DemoLog.log(String.format("%s connecting to localhost:%d...", this.getClass().getName(), DemoServer.PORT));
        try (Socket socket = new Socket("localhost", DemoServer.PORT)) {
            try (BufferedWriter out = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))) {
                byte[] bytes = new byte[size];
                Arrays.fill(bytes, (byte)'x');
                String toSend = new String(bytes);
                try {
                    for (int i = 0; i < runs; i++) {
                        DemoLog.log("[client]: sending #" + i);
                        out.write(toSend);
                        out.newLine();
                        out.flush();
                        DemoLog.log("[client]: sent #" + i);
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
