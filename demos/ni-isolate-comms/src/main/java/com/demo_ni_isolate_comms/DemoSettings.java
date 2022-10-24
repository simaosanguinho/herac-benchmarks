package com.demo_ni_isolate_comms;

import java.util.Arrays;

public final class DemoSettings {

    private static DemoSettings instance = null;

    public static DemoSettings get() {
        if (instance == null) {
            instance = new DemoSettings();
        }
        return instance;
    }


    public final int PORT = 12345;
    public final int MESSAGE_SIZE = 1024;
    public final byte[] MESSAGE_BYTES = new byte[MESSAGE_SIZE];
    public final String MESSAGE;

    private DemoSettings() {
        Arrays.fill(MESSAGE_BYTES, (byte)'x');
        MESSAGE = new String(MESSAGE_BYTES);
    }
}
