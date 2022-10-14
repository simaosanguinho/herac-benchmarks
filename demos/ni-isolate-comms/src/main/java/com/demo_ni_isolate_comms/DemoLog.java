package com.demo_ni_isolate_comms;

public class DemoLog {

    public static void log(String msg) {
        System.out.printf("[%d]: %s\n", System.nanoTime(), msg);
    }
    
}
