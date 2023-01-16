import com.oracle.svm.graalvisor.api.GraalVisorAPI;
import com.oracle.svm.graalvisor.types.GuestIsolateThread;

public class GraalvisorHostIsolateScalability {

    public static void executeInNewIsolate(String imgpath, String funname, long startTime) throws Exception {
        try (GraalVisorAPI gvapi = new GraalVisorAPI(imgpath)) {
            GuestIsolateThread guestThread = gvapi.createIsolate();
            gvapi.invokeFunction(guestThread, funname, String.format("{ \"time\": %s }" , startTime));
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
                throw new Exception("Not implemented!");
            } else {
                executeInNewIsolate(imgpath, funname, startTime);
            }
        }
    }

}
