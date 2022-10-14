package com.demo_ni_isolate_comms;

public class DemoIsolateComms {
    public static void main(String[] args) {
        if (args.length == 0) {
            usageError();
        }

        switch (args[0]) {
            case "--client":
                new DemoClient().run();
                break;
            case "--server":
                new DemoServer().run();
                break;
            default:
                break;
        }
    }

    private static void usageError() {
        System.err.println("usage: ./bench (--server | --client)");
        System.exit(1);
    }
}
