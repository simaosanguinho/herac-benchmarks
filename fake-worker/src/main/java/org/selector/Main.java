package org.selector;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Set;

public class Main {

    public static void main(String[] args) throws IOException {
        int port = 5454;
        if (args.length > 0) {
            port = Integer.parseInt(args[0]);
        }

        Selector selector = Selector.open();
        ServerSocketChannel serverSocket = ServerSocketChannel.open();
        serverSocket.bind(new InetSocketAddress("localhost", port));
        serverSocket.configureBlocking(false);
        serverSocket.register(selector, SelectionKey.OP_ACCEPT);
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        while (true) {
            int requests = 0;
            long before = System.currentTimeMillis();
            selector.select(5); // TODO: maybe selectNow()?
            Set<SelectionKey> selectedKeys = selector.selectedKeys();
            Iterator<SelectionKey> iter = selectedKeys.iterator();
            while (iter.hasNext()) {
                SelectionKey key = iter.next();
                if (key.isAcceptable()) {
                    register(selector, serverSocket);
                }
                if (key.isReadable()) {
                    read(buffer, key, before);
                }
                iter.remove();
                ++requests;
            }
            // System.out.println("Time took to add requests: " + (System.currentTimeMillis() - before) + ", requests: " + requests);
            before = System.currentTimeMillis();
            int processed = FakeWorker.processCallbacks(buffer);
            // System.out.println("Time took to process callbacks: " + (System.currentTimeMillis() - before) + ", processed: " + processed);
        }
    }

    private static void read(ByteBuffer buffer, SelectionKey key, long readTimestamp) throws IOException {
        SocketChannel client = (SocketChannel) key.channel();
        if (client.read(buffer) != -1) {
            buffer.flip();
            String payload = StandardCharsets.UTF_8.decode(buffer).toString().trim();
            FakeWorker.processPayload(payload, client, buffer, readTimestamp);
            buffer.clear();
            // The client will be closed in the future, handled by InvocationCallback.
        } else {
            client.close();
            System.out.println("End-of-stream, closing connection");
        }
    }

    private static void register(Selector selector, ServerSocketChannel serverSocket) throws IOException {
        SocketChannel client = serverSocket.accept();
        client.configureBlocking(false);
        client.register(selector, SelectionKey.OP_READ);
    }
}
