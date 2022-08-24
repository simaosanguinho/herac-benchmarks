import java.util.ArrayList;
import java.util.List;

import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.Isolates;
import org.graalvm.nativeimage.ObjectHandle;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.RuntimeOptions;
import org.graalvm.word.WordFactory;

public class IsolateScalabilityTest {

    @CEntryPoint
    static void invoke(@CEntryPoint.IsolateThreadContext IsolateThread processContext) {
        try {
            Thread.sleep(1000*60*60);
        } catch (InterruptedException e) {
            return;
        }
    }
    
    public static void main(String[] args) throws Exception {
        int target = Integer.parseInt(args[0]);
        int reserved = Integer.parseInt(args[1]);
        List<Thread> threads = new ArrayList<>(target);
        long start = System.currentTimeMillis();
        for (int i = 0; i < target; i++) {
            Thread t = new Thread() {
                @Override
                public void run() {
                    Isolates.CreateIsolateParameters.Builder builder = new Isolates.CreateIsolateParameters.Builder();
                    builder.auxiliaryImageReservedSpaceSize(WordFactory.zero());
                    builder.reservedAddressSpaceSize(WordFactory.unsigned(reserved));
                    IsolateThread isolateThread = Isolates.createIsolate(builder.build());
                    // TODO - warning, this test does not wait for the isolate to be created before checking the time! 
                    invoke(isolateThread);
                    Isolates.tearDownIsolate(isolateThread);
                }
            };
            t.start();
            threads.add(t);
        }
        long finish = System.currentTimeMillis();
        System.out.println(String.format("Creating %s threads took %s ms!", target, (finish - start)));
        System.out.println("Sleeping for 5 seconds...");
        Thread.sleep(5000);
        System.out.println("Sleeping for 5 seconds... done!");
        System.exit(0);
    }
}
