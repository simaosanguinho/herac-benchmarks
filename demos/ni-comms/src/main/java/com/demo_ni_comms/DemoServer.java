package com.demo_ni_comms;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;

public class DemoServer extends DemoAbstractTest {

    public static int PORT = 12345;

    protected void networkCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        DemoLog.log(String.format("[server]: starting on localhost:%d...", DemoServer.PORT));    
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            if (warmupRuns > 0) {
                DemoLog.log(String.format("[server]: warming up with %d runs...", warmupRuns));
                networkCommsTestRecvData(serverSocket, size, bufSize, true, warmupRuns);
                DemoLog.log("[server]: warmup complete");
            }

            networkCommsTestRecvData(serverSocket, size, bufSize, false, runs);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void networkCommsTestRecvData(ServerSocket serverSocket, int size, int bufSize, boolean isWarmup, int runs) throws IOException {
        DemoLog.log(String.format("[server]: waiting for client...", PORT));
        Socket client = serverSocket.accept();
        client.setTcpNoDelay(true);
        try (InputStream in = new BufferedInputStream(client.getInputStream(), bufSize == 0 ? size : bufSize)) {
            try {
                byte[] received = null;
                if (isWarmup) {
                    for (int i = 0; i < runs; i++) {
                        received = in.readNBytes(size);
                    }
                } else {
                    for (int i = 0; i < runs; i++) {
                        DemoLog.log("[server]: receiving #" + i);
                        received = in.readNBytes(size);
                        DemoLog.log("[server]: received #" + i);
                    }
                }
                assert received != null;
                assert received.length == size;
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
