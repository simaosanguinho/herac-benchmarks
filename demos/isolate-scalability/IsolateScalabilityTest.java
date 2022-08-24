import java.util.ArrayList;
import java.util.List;

import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.Isolates;
import org.graalvm.nativeimage.ObjectHandle;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.RuntimeOptions;
import org.graalvm.word.WordFactory;

public class IsolateScalabilityTest {

    public static void main(String[] args) throws Exception {
        int target = Integer.parseInt(args[0]);
        Isolates.CreateIsolateParameters.Builder builder = new Isolates.CreateIsolateParameters.Builder();
        builder.auxiliaryImageReservedSpaceSize(WordFactory.zero());
        builder.reservedAddressSpaceSize(WordFactory.unsigned(8388608));
        Isolates.CreateIsolateParameters parameters = builder.build();

        long start = System.nanoTime();
        for (int i = 0; i < target; i++) {
            Isolates.createIsolate(parameters);
        }
        long finish = System.nanoTime();

        System.out.println(String.format("Creating %s threads took %s us!", target, ((finish - start) / 1000)));
    }
}
