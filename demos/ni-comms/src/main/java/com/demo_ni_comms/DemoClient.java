package com.demo_ni_comms;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.Arrays;

public class DemoClient extends DemoAbstractTest {

    protected void tcpCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];

        byte[] bytes = new byte[size];
        Arrays.fill(bytes, (byte)'x');

        DemoLog.log(String.format("[client]: connecting to localhost:%d...", DemoServer.PORT));    
        try (Socket socket = new Socket("localhost", DemoServer.PORT)) {
            // socket.setTcpNoDelay(true);
            try (OutputStream out = new BufferedOutputStream(socket.getOutputStream(), bufSize == 0 ? size : bufSize)) {
                for (int i = 0; i < runs + warmupRuns; i++) {
                    tcpCommsTestSendData(out, bytes, i, size);
                    
                }
                printResults(warmupRuns, runs);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void tcpCommsTestSendData(OutputStream out, byte[] bytes, int i, int size) throws IOException {
        start[i] = System.nanoTime();
        out.write(bytes);
        stop[i] = System.nanoTime();
    }

    protected void udpCommsTest(int size, int bufSize, int runs, int warmupRuns) {
        start = new long[runs + warmupRuns];
        stop = new long[runs + warmupRuns];

        try (DatagramSocket socket = new DatagramSocket()) {
            byte[] bytes = new byte[size];
            Arrays.fill(bytes, (byte)'x');
            DatagramPacket datagram = new DatagramPacket(bytes, size, new InetSocketAddress("localhost", DemoServer.PORT));

            for (int i = 0; i < runs + warmupRuns; i++) {
                udpCommsTestRecvData(socket, datagram, i);
            }

            printResults(warmupRuns, runs);
        
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void udpCommsTestRecvData(DatagramSocket socket, DatagramPacket datagram, int i) throws IOException {
        start[i] = System.nanoTime();
        socket.send(datagram);
        stop[i] = System.nanoTime();
    }

    protected void printResults(int warmupRuns, int runs) {
        for (int i = 0; i < runs; i++) {
            DemoLog.log(start[warmupRuns + i], "[client]: sending #" + i);
            DemoLog.log(stop[warmupRuns + i], "[client]: sent #" + i);
        }
    }
}
