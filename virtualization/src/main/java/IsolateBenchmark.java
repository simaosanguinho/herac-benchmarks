import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.Isolates;
import org.graalvm.nativeimage.Isolates.CreateIsolateParameters;
import org.graalvm.nativeimage.c.function.CEntryPoint;

public class IsolateBenchmark {

	@CEntryPoint
	private static void execute(@CEntryPoint.IsolateThreadContext IsolateThread context, long startTime) {
		long finishTime = System.nanoTime();
		System.out.println((finishTime - startTime) / (float)1000000);
	}

	public static void executeInNewIsolate(int requests) {
		for (int i = 0; i < requests; i++) {
			long startTime = System.nanoTime();
			IsolateThread execContext = Isolates.createIsolate(CreateIsolateParameters.getDefault());
			execute(execContext, startTime);
			Isolates.tearDownIsolate(execContext);
		}
	}

	public static void main(String[] args) throws Exception {
		executeInNewIsolate(Integer.valueOf(args[0]));
	}
}
