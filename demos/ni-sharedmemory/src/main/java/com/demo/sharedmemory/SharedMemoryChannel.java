package com.demo.sharedmemory;

import java.io.File;
import java.io.IOException;
import java.nio.CharBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileChannel.MapMode;
import java.nio.file.StandardOpenOption;

public class SharedMemoryChannel {

    private final CharBuffer buffer;
    private final char[] readBuffer = new char[4096];

    private static final char readyToRead = '<';
    private static final char readyToWrite = '>';

    public SharedMemoryChannel(String path) throws IOException {
        FileChannel channel = FileChannel.open(
                (new File(path)).toPath(),
                StandardOpenOption.READ,
                StandardOpenOption.WRITE,
                StandardOpenOption.CREATE);
        buffer = channel.map(MapMode.READ_WRITE, 0, 4096).asCharBuffer();

    }

    public void initializeForWriting() {
        buffer.put(0, readyToWrite);
    }

    public void writeString(String s) throws InterruptedException {
        buffer.clear();
        while(buffer.get(0) != readyToWrite) {
            Thread.sleep(0, 100);
        }
        buffer.put(readyToWrite); // Advance the first char.

        buffer.put(s.toCharArray());
        buffer.put('\0');
        buffer.put(0, readyToRead);
    }

    public String readString() throws InterruptedException {
        buffer.clear();
        while(buffer.get(0) != readyToRead) {
            Thread.sleep(0, 100);
        }
        buffer.get(); // Advance the first char.

        char c;
        int size = 0;
        while((c = buffer.get()) != '\0') {
            readBuffer[size++] = c;
        }

        buffer.put(0, readyToWrite);
        return new String(readBuffer, 0, size);
    }
}
