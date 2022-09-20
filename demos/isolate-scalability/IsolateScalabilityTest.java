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
    private static long execute(@CEntryPoint.IsolateThreadContext IsolateThread context, long startTime) {
           long finishTime = System.nanoTime();
           return (finishTime - startTime) / 1000;
    }

    public static void main(String[] args) throws Exception {
        int target = Integer.parseInt(args[0]);
        long total = 0;
//        Isolates.CreateIsolateParameters.Builder builder = new Isolates.CreateIsolateParameters.Builder();
//        builder.auxiliaryImageReservedSpaceSize(WordFactory.zero());
//        builder.reservedAddressSpaceSize(WordFactory.unsigned(8388608));
//        Isolates.CreateIsolateParameters parameters = builder.build();
        Isolates.CreateIsolateParameters parameters = Isolates.CreateIsolateParameters.getDefault();

        for (int i = 0; i < target; i++) {
            long startTime = System.nanoTime();
            IsolateThread it = Isolates.createIsolate(parameters);
            total += execute(it, startTime);
        }

        System.out.println(String.format("Creating %s threads took %s us!", target, (total / target)));
    }
}
