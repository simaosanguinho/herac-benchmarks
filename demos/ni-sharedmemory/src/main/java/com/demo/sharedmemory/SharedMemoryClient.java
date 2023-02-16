package com.demo.sharedmemory;

import java.io.IOException;

public class SharedMemoryClient {

    public static void main(String[] args) throws IOException, InterruptedException {
        SharedMemoryChannel c2s = new SharedMemoryChannel("/tmp/shared-client-2-server");
        SharedMemoryChannel s2c = new SharedMemoryChannel("/tmp/shared-server-2-client");

        c2s.initializeForWriting();

        for(int i = 0; i < 10; i++) {
            System.out.println("Receiving from server");
            String s = s2c.readString();
            System.out.println("Received from server: " + s);

            s = s.toLowerCase();
            System.out.println("Sending to server: " + s);
            c2s.writeString(s);
            System.out.println("Sent to server: " + s);
        }
    }
}
