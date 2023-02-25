import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Engine;
import org.graalvm.polyglot.HostAccess;
import org.graalvm.polyglot.Source;
import org.graalvm.polyglot.Value;
import java.util.HashMap;
import java.util.Map;

public final class JsLauncherSnapshotsIsolates {

    public static void main(String[] args) {
        String toEval = null;
        for (int i = 0; i < args.length; i++) {
            String arg = args[i];
            if (arg.equals("-e")) {
                i++;
                if (i < args.length) {
                    if (toEval == null) {
                        toEval = args[i];
                    } else {
                        throw usage();
                    }
                } else {
                    throw usage();
                }
            } else {
                throw usage();
            }
        }
        if (toEval == null) {
            throw usage();
        }

        Map<String,String> options = new HashMap<>();
        // Options for Auxiliary Engine Caching
        // Reference: https://www.graalvm.org/22.1/graalvm-as-a-platform/language-implementation-framework/AuxiliaryEngineCachingEnterprise/#usage
        options.put("engine.Cache", "cache.image");
        options.put("engine.CacheCompile", "executed");
        options.put("engine.TraceCache", "true");
        options.put("engine.TraceCompilation", "true");

        // Options for Truffle Isolates
        options.put("engine.SpawnIsolate", "true");
        options.put("engine.IsolateOption.Dump", "Truffle:1");
        options.put("engine.IsolateOption.PrintGraph", "Network");
        options.put("engine.IsolateOption.TraceDeoptimization", "true");

        Source source = Source.create("js", toEval);

        try (Engine engine = Engine.newBuilder().allowExperimentalOptions(true).options(options).build()) {
            try (Context context = Context.newBuilder().engine(engine).allowHostAccess(HostAccess.ALL).build()) {
                Value result = context.eval(source);
                System.out.println(result);
            }
        }
    }

    private static RuntimeException usage() {
        System.err.println("usage: js -e 'program'");
        System.exit(1);
        return null;
    }
}
