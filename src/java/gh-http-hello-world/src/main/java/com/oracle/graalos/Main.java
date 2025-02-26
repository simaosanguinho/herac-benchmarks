package com.oracle.graalos;

import java.net.InetSocketAddress;
import com.sun.net.httpserver.HttpServer;


public class Main {

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(9001), 0);
        server.setExecutor(java.util.concurrent.Executors.newSingleThreadExecutor());
        server.createContext("/helloworld", new SimpleHttpHandler());
        server.start();
    }

}
