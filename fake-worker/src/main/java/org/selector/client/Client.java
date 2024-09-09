package org.selector.client;

import org.selector.utils.NetworkUtils;

public class Client {

    public static void main(String[] args) {
        if (args.length > 0 && "async".equals(args[0])) {
            System.out.println("Sending async");
            NetworkUtils.sendPost("localhost:5454", "/test", "application/json; charset=UTF-8", "aaa".getBytes(), true);
            sleep(1000);
        } else if (args.length > 1 && "load".equals(args[0])) {
            int req = Integer.parseInt(args[1]);
            System.out.println("Sending load: " + req);
            for (int i = req; i > 0; i--) {
                NetworkUtils.sendPost("localhost:5454", "/test", "application/json; charset=UTF-8", "aaa".getBytes(), true);
                sleep(1);
            }
            sleep(20000);
        } else {
            System.out.println("Sending sync");
            NetworkUtils.sendPost("localhost:5454", "/test", "application/json; charset=UTF-8", "aaa".getBytes(), false);
        }
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) { }
    }
}
