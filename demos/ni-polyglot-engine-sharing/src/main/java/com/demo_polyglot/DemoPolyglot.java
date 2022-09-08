package com.demo_polyglot;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import org.graalvm.polyglot.Context;
import org.graalvm.polyglot.Engine;
import org.graalvm.polyglot.Source;
import org.graalvm.polyglot.Value;

public class DemoPolyglot {
 
	private static long getMemoryFootprint_MBs() {
		return (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) / (1024 * 1024);
	}
	
    public static void main(String[] args) {
    	String javaHome = System.getenv("JAVA_HOME");
    	Map<String, String> options = new HashMap<>();
    	long time1, time2, time3;

    	if (args.length == 0) {
    		System.err.println("Syntax: DemoPolyglot <path to python source file>");
            System.exit(1);	
    	}
    	
        if (javaHome == null) {
            System.err.println("JAVA_HOME not found in the environment. Polyglot functionality significantly limited.");
            System.exit(1);
        }
        
        // Path to languages.
        System.setProperty("org.graalvm.language.python.home", javaHome + "/languages/python");
        System.setProperty("org.graalvm.language.llvm.home", javaHome + "/languages/llvm");
        System.setProperty("org.graalvm.language.js.home", javaHome + "/languages/js");

        // Python options.
        options.put("python.ForceImportSite", "true");
        options.put("python.Executable", javaHome + "/graalvisor-python-venv/bin/python");
    	
        System.out.println(String.format("Before Engine memory (MBs) = %s", getMemoryFootprint_MBs()));
        try (Engine engine = Engine.create()) {
            Source source = Source.newBuilder("python", new File(args[0])).buildLiteral();
            System.out.println(String.format("Before Context1 memory (MBs) = %s", getMemoryFootprint_MBs()));
            time1 = System.currentTimeMillis();
            
            try (Context context = Context.newBuilder().allowAllAccess(true).options(options).engine(engine).build()) {
                context.eval(source);
                Value function = context.eval("python", "main");
                System.out.println(function.execute("http://localhost:8000/snap.png").toString());
            }
            System.out.println(String.format("Before Engine2 memory (MBs) = %s", getMemoryFootprint_MBs()));
            time2 = System.currentTimeMillis();

            try (Context context = Context.newBuilder().allowAllAccess(true).options(options).engine(engine).build()) {
                context.eval(source);
                Value function = context.eval("python", "main");
                System.out.println(function.execute("http://localhost:8000/snap.png").toString());
            }
            System.out.println(String.format("Finish (MBs) = %s", getMemoryFootprint_MBs()));
            time3 = System.currentTimeMillis();
        }
        System.out.println(String.format("Context 1 took = %s, Context 2 took = %s", (time2 - time1), (time3 - time2)));
    }
}