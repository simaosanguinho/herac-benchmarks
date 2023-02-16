package com.demo.sharedmemory;

public class SharedMemoryServer {

    public static void main(String[] args) throws Exception {
        String s = "Hello Client!";
        SharedMemoryChannel c2s = new SharedMemoryChannel("/tmp/shared-client-2-server");
        SharedMemoryChannel s2c = new SharedMemoryChannel("/tmp/shared-server-2-client");

        s2c.initializeForWriting();

        for (int i = 0; i < 10; i++) {
            System.out.println("Sending to client: " + s);
            s2c.writeString(s);
            System.out.println("Sent to client: " + s);

            System.out.println("Receiving from client");
            s = c2s.readString();
            System.out.println("Received to client: " + s);
        }
    }
}
