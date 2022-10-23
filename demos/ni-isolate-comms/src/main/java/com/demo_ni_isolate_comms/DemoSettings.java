package com.demo_ni_isolate_comms;

import java.nio.CharBuffer;

public final class DemoSettings {

    private static DemoSettings instance = null;

    public static DemoSettings get() {
        if (instance == null) {
            instance = new DemoSettings();
        }
        return instance;
    }


    public final int PORT = 12345;
    public final int WARMUP_RUNS = 10;
    public final int RUNS = 10000;
    public final int MESSAGE_SIZE = 100;
    public final String MESSAGE = CharBuffer.allocate(MESSAGE_SIZE).toString().replace('\0', 'x');

    private DemoSettings() {
    }
}
