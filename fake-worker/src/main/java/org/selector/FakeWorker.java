package org.selector;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.PriorityQueue;
import java.util.function.Consumer;

public class FakeWorker {

    private static final String DURATION_HEADER = "X-Sleep-Duration: ";
    private static final String UPLOAD_HEADER = "POST /upload_function";

    private static final String HTTP_SUCCESS_RESPONSE = "HTTP/1.1 200 OK\r\n"
            + "Content-Type: text/plain; charset=utf-8\r\n"
            + "\r\n"
            + "%d %d";

    private static final String HTTP_UNKNOWN_RESPONSE = "HTTP/1.1 400 Bad Request\r\n"
            + "Content-Type: text/plain; charset=utf-8\r\n"
            + "\r\n"
            + "Unknown request type! Supported: function registration (POST to path /upload_function) and invocation (with X-Sleep-Duration header).";

    private static final PriorityQueue<InvocationCallback> callbacks = new PriorityQueue<>();


    public static void processPayload(String payload, SocketChannel client, ByteBuffer buffer, long readTimestamp) {
        if (payload.contains(DURATION_HEADER)) {
            int beginIdx = payload.indexOf(DURATION_HEADER) + DURATION_HEADER.length();
            String res = payload.substring(beginIdx);
            res = res.substring(0, indexOfWhitespace(res));
            int duration = Integer.parseInt(res);

            callbacks.offer(new InvocationCallback(System.currentTimeMillis() + duration, client, readTimestamp));
        } else if (payload.contains(UPLOAD_HEADER)) {
            // Return immediately.
            writeResponse(String.format(HTTP_SUCCESS_RESPONSE, readTimestamp, System.currentTimeMillis()), client, buffer);
        } else {
            System.out.println("Warning: unknown request type. Payload:");
            System.out.println(payload);
            writeResponse(HTTP_UNKNOWN_RESPONSE, client, buffer);
        }
    }

    public static int processCallbacks(ByteBuffer buffer) {
        int processed = 0;
        long currentTimestamp = System.currentTimeMillis();
        InvocationCallback cb;
        while ((cb = callbacks.peek()) != null && cb.callbackTimestamp < currentTimestamp) {
            callbacks.remove();
            cb.accept(buffer);
            ++processed;
        }
        System.out.println("Max remaining: " + (callbacks.stream().mapToInt(InvocationCallback::getEstimatedTime).max().orElse(0)));
        System.out.println("Num above 5000: " + (callbacks.stream().mapToInt(InvocationCallback::getEstimatedTime).filter(x -> x > 5000).count()));
        System.out.println("Num total: " + (callbacks.size()));
        return processed;
    }

    static class InvocationCallback implements Consumer<ByteBuffer>, Comparable<InvocationCallback> {

        private final long callbackTimestamp;
        private final SocketChannel client;
        private final long readTimestamp;

        private InvocationCallback(long callbackTimestamp, SocketChannel client, long readTimestamp) {
            this.callbackTimestamp = callbackTimestamp;
            this.client = client;
            this.readTimestamp = readTimestamp;
        }

        public int getEstimatedTime() {
            return (int) (this.callbackTimestamp - System.currentTimeMillis());
        }

        @Override
        public void accept(ByteBuffer buffer) {
            writeResponse(String.format(HTTP_SUCCESS_RESPONSE, readTimestamp, System.currentTimeMillis()), client, buffer);
        }

        @Override
        public int compareTo(InvocationCallback other) {
            return Long.compare(callbackTimestamp, other.callbackTimestamp);
        }

        @Override
        public String toString() {
            return "InvocationCallback [callbackTimestamp=" + callbackTimestamp + "]";
        }
    }

    private static void writeResponse(String responseString, SocketChannel client, ByteBuffer buffer) {
        try {
            buffer.clear();
            buffer.put(responseString.getBytes());
            buffer.flip();
            client.write(buffer);
            client.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        } finally {
            buffer.clear();
        }
    }

    private static int indexOfWhitespace(String input) {
        int index = 0;
        for (; index < input.length(); index++) {
            if (Character.isWhitespace(input.charAt(index))) {
                break;
            }
        }
        return index;
    }
}
