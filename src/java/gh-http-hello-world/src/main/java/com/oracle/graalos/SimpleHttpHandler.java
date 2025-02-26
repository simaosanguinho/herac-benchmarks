package com.oracle.graalos;

import java.io.IOException;
import java.io.OutputStream;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;


public class SimpleHttpHandler implements HttpHandler {

    @Override
    public void handle(HttpExchange he) throws IOException {
        // Handling CORS
        he.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
        if (he.getRequestMethod().equalsIgnoreCase("OPTIONS")) {
            he.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, OPTIONS");
            he.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type,Authorization");
            he.sendResponseHeaders(204, -1);
            return;
        }

        String response = "Hello, World!\n";

        he.sendResponseHeaders(200, response.length());
        OutputStream os = he.getResponseBody();
        os.write(response.getBytes());
        os.close();
    }
}

