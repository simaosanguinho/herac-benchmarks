package com.demo_ni_isolate_comms;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;

public class DemoServer {

    public void run() {
        DemoSettings settings = DemoSettings.get();
        try (ServerSocket serverSocket = new ServerSocket(settings.PORT)) {
            DemoLog.log(String.format("%s started on port %d, waiting for client...", this.getClass().getName(), settings.PORT));
            Socket client = serverSocket.accept();
            try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()))) {
                try {
                    DemoLog.log("[server]: receiving");
                    String received = in.readLine();
                    DemoLog.log("[server]: received");
                    assert received != null;
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
    
}
