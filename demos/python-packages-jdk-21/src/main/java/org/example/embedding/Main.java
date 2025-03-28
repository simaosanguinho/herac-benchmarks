package org.example.embedding;


import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Source;
import org.graalvm.polyglot.Value;
import org.graalvm.polyglot.io.IOAccess;

import java.net.InetSocketAddress;
import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.HashMap;
import java.io.OutputStream;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * A basic polyglot application that tries to exercise a simple hello world style program with NumPy.
 */
public class Main {

    public static void main(String[] args) {

        if (System.getenv("venv") == null) {
            System.err.println("Provide 'venv' environment variable pointing to the venv directory.");
            System.exit(1);
        }

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

        Path executable = Paths.get(System.getenv("venv"), "bin", "python");

        Map<String, Object> res = new HashMap<>();
        try (Context context = Context.newBuilder()
                .option("python.Executable", executable.toAbsolutePath().toString())
                .option("python.ForceImportSite", "true")
                .allowAllAccess(true)
                .build()) {

            Value result = context.eval("python", "import numpy; res = numpy.mean([2, 3, 4]); str(res)");

            res.put("result", result.asString());
            res.put("finish", "End of execution.");
        }
        return res;
    }
}
