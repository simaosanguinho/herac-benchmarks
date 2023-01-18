import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;

import org.graalvm.nativeimage.StackValue;
import org.graalvm.nativeimage.c.function.CFunction;
import org.graalvm.nativeimage.c.type.CIntPointer;

import com.oracle.svm.graalvisor.api.GraalVisorAPI;
import com.oracle.svm.graalvisor.types.GuestIsolateThread;

public class GraalvisorHostIsolateScalability {

    @CFunction
    public static native int fork();

    @CFunction
    public static native int waitpid(int pid, CIntPointer stat_loc, int options);

    public static ArrayList<Integer> pids = new ArrayList<>();
    public static ArrayList<Thread> threads = new ArrayList<>();

    public static void executeInNewIsolate(String imgpath, String funname, long startTime) throws Exception {
        try (GraalVisorAPI gvapi = new GraalVisorAPI(imgpath)) { // TODO - the next step is to load this before.
            GuestIsolateThread guestThread = gvapi.createIsolate();
            gvapi.invokeFunction(guestThread, funname, String.format("{ \"time\": %s }" , startTime));
            Thread.sleep(10*1000); // Allow time for memory measurement.
            gvapi.tearDownIsolate(guestThread);
        }
    }

    public static void executeInNewThread(String imgpath, String funname, long startTime) throws Exception {
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    executeInNewIsolate(imgpath, funname, startTime);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
        threads.add(t);
        t.start();
    }

    public static void executeInNewProcess(String imgpath, String funname, long startTime) throws Exception {
        int pid = fork();
        if (pid == 0) {
            executeInNewIsolate(imgpath, funname, startTime);
            System.exit(0);
        } else {
            pids.add(pid);
        }
    }

    public static void main(String[] args) throws Exception {
        boolean shouldfork = Boolean.parseBoolean(args[0]);
        int requests = Integer.parseInt(args[1]);
        String imgpath = args[2];
        String funname = args[3];

        for (int i = 0; i < requests; i++) {
            long startTime = System.nanoTime();
            if (shouldfork) {
                executeInNewProcess(imgpath, funname, startTime);
            } else {
                executeInNewThread(imgpath, funname, startTime);
            }
            Thread.sleep(50); // Avoid stdout clash.
        }

        Thread.sleep(1); // Allow all processes/threads to reach their sleep.

        long rssKB = MemoryUtils.getRSSKb(ProcessHandle.current().pid());
        if (shouldfork) {
            for (Integer pid : pids) {
                rssKB += MemoryUtils.getRSSKb(pid);
            }
            for (Integer pid : pids) {
                CIntPointer statusptr = StackValue.get(CIntPointer.class);
                waitpid(pid, statusptr, 0);
            }
        } else {
            for (Thread t : threads) {
                t.join();
            }
        }
        System.out.println(String.format("Memory utilization (RSS) = %s KBs", rssKB));
    }
}
