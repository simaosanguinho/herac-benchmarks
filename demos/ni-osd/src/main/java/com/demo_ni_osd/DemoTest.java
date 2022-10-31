package com.demo_ni_osd;

import java.util.Arrays;
import java.util.function.Supplier;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class DemoTest {

    private Object[] toSerialize;
    private String[] toDeserialize;
    private Object[] results;
    private long[] start;
    private long[] stop;

    public void sRStr064(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RString64(), runs, warmupRuns);
    }

    public void sRStr128(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RString128(), runs, warmupRuns);
    }

    public void sRInt4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RInt4(), runs, warmupRuns);
    }

    public void sRInt8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RInt8(), runs, warmupRuns);
    }

    public void sALst4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.AList4(), runs, warmupRuns);
    }

    public void sALst8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.AList8(), runs, warmupRuns);
    }

    public void sHMap4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.HMap4(), runs, warmupRuns);
    }

    public void sHMap8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.HMap8(), runs, warmupRuns);
    }

    private void ser(Supplier<Object> objectSupplier, int runs, int warmupRuns) {
        DemoLog.log("[serializer]: processing object of type " + objectSupplier.get().getClass().getName());

        Gson gson = new GsonBuilder().create();
        prepareTest(objectSupplier, warmupRuns, runs);

        for (int i = 0; i < runs + warmupRuns; i++) {
            serOne(gson, i);
        }

        consumeResults();
    }

    public void serOne(Gson gson, int i) {
        start[i] = System.nanoTime();
        results[i] = gson.toJson(toSerialize[i]);
        stop[i] = System.nanoTime();
    }


    public void dRStr064(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RString64(), runs, warmupRuns);
    }

    public void dRStr128(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RString128(), runs, warmupRuns);
    }

    public void dRInt4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RInt4(), runs, warmupRuns);
    }

    public void dRInt8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RInt8(), runs, warmupRuns);
    }

    public void dALst4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.AList4(), runs, warmupRuns);
    }

    public void dALst8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.AList8(), runs, warmupRuns);
    }

    public void dHMap4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.HMap4(), runs, warmupRuns);
    }

    public void dHMap8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.HMap8(), runs, warmupRuns);
    }

    private void deser(Supplier<Object> objectSupplier, int runs, int warmupRuns) {
        DemoLog.log("[deserializer]: processing object of type " + objectSupplier.get().getClass().getName());

        Gson gson = new GsonBuilder().create();
        prepareTest(objectSupplier, warmupRuns, runs);
        Class<?> clazz = objectSupplier.get().getClass();

        for (int i = 0; i < runs + warmupRuns; i++) {
            deserOne(gson, i, clazz);
        }

        consumeResults();
    }

    public void deserOne(Gson gson, int i, Class<?> clazz) {
        start[i] = System.nanoTime();
        results[i] = gson.fromJson(toDeserialize[i], clazz);
        stop[i] = System.nanoTime();
    }

    public void printResults(int warmupRuns, int runs) {
        for (int i = 0; i < runs; i++) {
            DemoLog.log(start[warmupRuns + i], "[json]: start #" + i);
            DemoLog.log(stop[warmupRuns + i], "[json]: stop #" + i);
        }
    }

    private void prepareTest(Supplier<Object> objectSupplier, int warmupRuns, int runs) {
        int total = warmupRuns + runs;
        start = new long[total];
        stop = new long[total];
        toSerialize = new Object[total];
        toDeserialize = new String[total];
        results = new Object[total];
        Gson gson = new GsonBuilder().create();
        for (int i = 0; i < total; i++) {
            Object o = objectSupplier.get();
            toSerialize[i] = o;
            toDeserialize[i] = gson.toJson(o);
        }
    }

    private void consumeResults() {
        DemoLog.log("[blackhole]: Consuming results: " + Arrays.hashCode(results));
    }
}
