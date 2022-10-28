package com.demo_ni_osd;

import java.util.function.Supplier;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class DemoTest {

    public void serSmall4(int runs, int warmupRuns) {
        ser(() -> new DemoObject.Small4(), runs, warmupRuns);
    }

    public void serSmall8(int runs, int warmupRuns) {
        ser(() -> new DemoObject.Small8(), runs, warmupRuns);
    }

    private void ser(Supplier<Object> objectSupplier, int runs, int warmupRuns) {
        DemoLog.log("[serializer]: processing object of type " + objectSupplier.get().getClass().getName());

        Gson gson = new GsonBuilder().create();

        for (int i = 0; i < warmupRuns; i++) {
            Object o = objectSupplier.get();
            String json = gson.toJson(o);
            DemoLog.log("[serializer]: warmup #" + i + " : " + json);
        }
        
        for (int i = 0; i < runs; i++) {
            Object o = objectSupplier.get();
            DemoLog.log("[serializer]: serializing #" + i);
            String json = gson.toJson(o);
            DemoLog.log("[serializer]: serialized #" + i + " : " + json);
        }
    }


    public void deserSmall4(int runs, int warmupRuns) {
        deser(() -> new DemoObject.Small4(), runs, warmupRuns);
    }

    public void deserSmall8(int runs, int warmupRuns) {
        deser(() -> new DemoObject.Small8(), runs, warmupRuns);
    }

    private void deser(Supplier<Object> objectSupplier, int runs, int warmupRuns) {
        DemoLog.log("[deserializer]: processing object of type " + objectSupplier.get().getClass().getName());

        Gson gson = new GsonBuilder().create();
        Object o = objectSupplier.get();
        Class<?> clazz = o.getClass();
        String json = gson.toJson(o);

        for (int i = 0; i < warmupRuns; i++) {
            Object deserialized = gson.fromJson(json, clazz);
            assert deserialized.getClass().equals(clazz);
        }
        
        for (int i = 0; i < runs; i++) {
            DemoLog.log("[deserializer]: deserializing #" + i);
            Object deserialized = gson.fromJson(json, clazz);
            DemoLog.log("[deserializer]: deserialized #" + i);
            assert deserialized.getClass().equals(clazz);
        }
    }

}
