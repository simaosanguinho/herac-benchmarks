package com.demo_ni_isolate_comms;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.util.Arrays;

public class DemoClient extends DemoAbstractTest {

    protected void networkCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        if (warmupRuns > 0) {
            DemoLog.log(String.format("[client]: warming up with %d runs...", warmupRuns));
            networkCommsTestSendData(true, size, bufSize, warmupRuns);
            DemoLog.log("[client]: warmup complete");
        }

        networkCommsTestSendData(false, size, bufSize, runs);
    }

    private void networkCommsTestSendData(boolean isWarmup, int size, int bufSize, int runs) {
        DemoLog.log(String.format("[client]: connecting to localhost:%d...", DemoServer.PORT));    
        try (Socket socket = new Socket("localhost", DemoServer.PORT)) {
            socket.setTcpNoDelay(true);
            try (OutputStream out = new BufferedOutputStream(socket.getOutputStream(), bufSize == 0 ? size : bufSize)) {
                byte[] bytes = new byte[size];
                Arrays.fill(bytes, (byte)'x');
                try {
                    for (int i = 0; i < runs; i++) {
                        if (!isWarmup) {
                            DemoLog.log("[client]: sending #" + i);
                        }
                        out.write(bytes);
                        if (!isWarmup) {
                            DemoLog.log("[client]: sent #" + i);
                        }
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
