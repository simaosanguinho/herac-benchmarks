package com.demo_polyglot;

import java.util.Map;
import java.util.HashMap;
import org.graalvm.polyglot.Engine;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.HostAccess;
import org.graalvm.options.OptionDescriptor;

public class DemoPolyglot {

    public static void nocompilation() {
	Map<String, String> options = new HashMap<>();
	options.put("engine.Compilation", "false");
        Context context = Context.newBuilder().allowAllAccess(true).allowExperimentalOptions(true).options(options).build();
	for (int i = 0; i < 1; i++) {
            context.eval("python", "print(1 + 1)");
        }
        context.close();
    }

    public static void compilation() {
	Engine engine = Engine.create();
        Context context = Context.newBuilder().allowAllAccess(true).engine(engine).build();
	for (int i = 0; i < 1; i++) {
            context.eval("python", "print(1 + 1)");
        }
        context.close();
    }

    public static void main(String[] args) {
        long start = System.currentTimeMillis();
        nocompilation();
        long mid = System.currentTimeMillis();
	compilation();
        long end = System.currentTimeMillis();
	System.out.println(String.format("No compilation %s, Compilation %s", (mid - start), (end - mid)));
    }
}
