package com.demo_ni_isolate_comms;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;

public class DemoServer {

    public void networkCommsTest(int runs, int warmupRuns) {
        DemoSettings settings = DemoSettings.get();
        try (ServerSocket serverSocket = new ServerSocket(settings.PORT)) {
            DemoLog.log(String.format("%s started on port %d, waiting for client...", this.getClass().getName(), settings.PORT));
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
