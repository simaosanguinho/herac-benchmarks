package com.demo_ni_isolate_comms;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.Socket;

public class DemoClient {

    public void run() {
        DemoSettings settings = DemoSettings.get();
        DemoLog.log(String.format("%s connecting to localhost:%d...", this.getClass().getName(), settings.PORT));
        try (Socket socket = new Socket("localhost", settings.PORT)) {
            try (BufferedWriter out = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))) {
                String toSend = settings.MESSAGE;
                try {
                    DemoLog.log("[client]: sending");
                    out.write(toSend);
                    out.newLine();
                    out.flush();
                    DemoLog.log("[client]: sent");
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
    
}
