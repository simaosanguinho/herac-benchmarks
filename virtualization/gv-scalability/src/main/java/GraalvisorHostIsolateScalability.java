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

    public static void executeInNewIsolate(GraalVisorAPI gvapi, String imgpath, String funname, long startTime) throws Exception {
        GuestIsolateThread guestThread = gvapi.createIsolate();
        gvapi.invokeFunction(guestThread, funname, String.format("{ \"time\": %s }" , startTime));
        Thread.sleep(10*1000); // Allow time for memory measurement.
        gvapi.tearDownIsolate(guestThread);
    }

    public static void executeInNewThread(String imgpath, String funname, long startTime) throws Exception {
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                try (GraalVisorAPI gvapi = new GraalVisorAPI(imgpath)) {
                    executeInNewIsolate(gvapi, imgpath, funname, startTime);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
        threads.add(t);
        t.start();
    }

    public static void executeInNewProcess(GraalVisorAPI gvapi, String imgpath, String funname, long startTime) throws Exception {
        int pid = fork();
        if (pid == 0) {
            executeInNewIsolate(gvapi, imgpath, funname, startTime);
            System.exit(0);
        } else {
            pids.add(pid);
        }
    }

    // TODO - have results without pre-loading the app?
    public static void main(String[] args) throws Exception {
        boolean shouldfork = args[0].equals("process") ? true : false;
        int requests = Integer.parseInt(args[1]);
        String imgpath = args[2];
        String funname = args[3];
        GraalVisorAPI gvapi = shouldfork ? new GraalVisorAPI(imgpath) : null;

        for (int i = 0; i < requests; i++) {
            long startTime = System.nanoTime();
            if (shouldfork) {
                executeInNewProcess(gvapi, imgpath, funname, startTime);
            } else {
                executeInNewThread(imgpath, funname, startTime);
            }
            Thread.sleep(50); // Avoid stdout clash.
        }

        Thread.sleep(1); // Allow all processes/threads to reach their sleep.

        long rssKB = MemoryUtils.getRSSKb(ProcessHandle.current().pid());
        long pssKB = MemoryUtils.getPSSKb(ProcessHandle.current().pid());
        if (shouldfork) {
            for (Integer pid : pids) {
                rssKB += MemoryUtils.getRSSKb(pid);
                pssKB += MemoryUtils.getPSSKb(pid);
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
        System.out.println(String.format("Memory utilization RSS / PSS = %s / %s KBs", rssKB, pssKB));
    }
}
