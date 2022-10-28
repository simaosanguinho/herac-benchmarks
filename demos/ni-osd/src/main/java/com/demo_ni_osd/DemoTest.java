package com.demo_ni_osd;

import java.util.function.Supplier;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class DemoTest {

    public void serRString64(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RString64(), runs, warmupRuns);
    }

    public void serRString128(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RString128(), runs, warmupRuns);
    }

    public void serRInt4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RInt4(), runs, warmupRuns);
    }

    public void serRInt8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.RInt8(), runs, warmupRuns);
    }

    public void serAList4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.AList4(), runs, warmupRuns);
    }

    public void serAList8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.AList8(), runs, warmupRuns);
    }

    public void serHMap4(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.HMap4(), runs, warmupRuns);
    }

    public void serHMap8(int runs, int warmupRuns) {
        ser(() -> new DemoObjects.HMap8(), runs, warmupRuns);
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


    public void deserRString64(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RString64(), runs, warmupRuns);
    }

    public void deserRString128(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RString128(), runs, warmupRuns);
    }

    public void deserRInt4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RInt4(), runs, warmupRuns);
    }

    public void deserRInt8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.RInt8(), runs, warmupRuns);
    }

    public void deserAList4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.AList4(), runs, warmupRuns);
    }

    public void deserAList8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.AList8(), runs, warmupRuns);
    }

    public void deserHMap4(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.HMap4(), runs, warmupRuns);
    }

    public void deserHMap8(int runs, int warmupRuns) {
        deser(() -> new DemoObjects.HMap8(), runs, warmupRuns);
    }

    private void deser(Supplier<Object> objectSupplier, int runs, int warmupRuns) {
        DemoLog.log("[deserializer]: processing object of type " + objectSupplier.get().getClass().getName());

        Gson gson = new GsonBuilder().create();

        for (int i = 0; i < warmupRuns; i++) {
            Object o = objectSupplier.get();
            Class<?> clazz = o.getClass();
            String json = gson.toJson(o);
            Object deserialized = gson.fromJson(json, clazz);
            assert deserialized.getClass().equals(clazz);
            DemoLog.log("[deserializer]: warmup #" + deserialized);
        }
        
        for (int i = 0; i < runs; i++) {
            Object o = objectSupplier.get();
            Class<?> clazz = o.getClass();
            String json = gson.toJson(o);
            DemoLog.log("[deserializer]: deserializing #" + i);
            Object deserialized = gson.fromJson(json, clazz);
            DemoLog.log("[deserializer]: deserialized #" + i);
            assert deserialized.getClass().equals(clazz);
        }
    }

}
