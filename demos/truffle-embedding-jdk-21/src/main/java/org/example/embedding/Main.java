package org.example.embedding;


import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Source;
import org.graalvm.polyglot.Value;

import java.net.InetSocketAddress;
import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.HashMap;
import java.io.OutputStream;

/**
 * A basic polyglot application that tries to exercise a simple hello world style program in all installed languages.
 */
public class Main {

    public static void main(String[] args) {
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress(9001), 0);
            server.setExecutor(java.util.concurrent.Executors.newSingleThreadExecutor());
            server.createContext("/invoke", new HttpHandler() {
                @Override
                public void handle(HttpExchange exchange) throws IOException {
                    String response;
                    try {
                        response = workload().toString() + "\n";
                    } catch (Exception e) {
                        response = e.getMessage();
                        e.printStackTrace();
                    }
                    exchange.sendResponseHeaders(200, response.getBytes().length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                }
            });
            server.start();
            System.out.println("Server is running on port 9001");
        } catch (Exception e) {
            e.printStackTrace(System.err);
            System.exit(1);
        }
    }


    public static Map<String, Object> workload() {
        Map<String, Object> res = new HashMap<>();
        try (Context context = Context.newBuilder().allowAllAccess(true).build()) {
            Set<String> languages = context.getEngine().getLanguages().keySet();
            for (String id : languages) {
                res.put(id + "_init", "Initializing language " + id);
                context.initialize(id);
                switch (id) {
                    case "python":
                        res.put("python", context.eval("python", "'Hello Python!'").asString());
                        break;
                    case "js":
                        res.put("js", context.eval("js", "'Hello JavaScript!'").asString());
                        break;
                }
            }
            res.put("finish", "End of execution.");
        }
        return res;
    }
}
