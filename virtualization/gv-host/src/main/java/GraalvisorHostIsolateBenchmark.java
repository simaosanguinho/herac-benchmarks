import com.oracle.svm.graalvisor.api.GraalVisorAPI;
import com.oracle.svm.graalvisor.types.GuestIsolateThread;

public class GraalvisorHostIsolateBenchmark {

	public static void executeInNewIsolate(int requests, String imgpath, String funname) throws Exception {
		for (int i = 0; i < requests; i++) {
			long startTime = System.nanoTime();
			try (GraalVisorAPI gvapi = new GraalVisorAPI(imgpath)) {
				GuestIsolateThread guestThread = gvapi.createIsolate();
				String res = gvapi.invokeFunction(guestThread, funname, String.format("{ \"time\": %s }" , System.nanoTime()));
				gvapi.tearDownIsolate(guestThread);
			}
		}
	}

	public static void main(String[] args) throws Exception {
		int requests = Integer.parseInt(args[0]);
		String imgpath = args[1];
		String funname = args[2];
		executeInNewIsolate(requests, imgpath, funname);
	}
}
