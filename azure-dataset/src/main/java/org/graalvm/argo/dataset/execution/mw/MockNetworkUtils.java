package org.graalvm.argo.dataset.execution.mw;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class MockNetworkUtils {

    private static final ExecutorService executor = Executors.newFixedThreadPool(25000);

    public static void sendPost(Runnable asyncRunnable) {
        executor.execute(asyncRunnable);
    }

    public static void shutdown() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(600, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
        }
    }

}

