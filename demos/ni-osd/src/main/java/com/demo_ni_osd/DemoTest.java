package com.demo_ni_osd;

public class DemoTest {

    public void serializeSmall4(int runs, int warmupRuns) {
        serialize(new DemoObject.Small4(), runs, warmupRuns);
    }

    public void serializeSmall8(int runs, int warmupRuns) {
        serialize(new DemoObject.Small8(), runs, warmupRuns);
    }

    private void serialize(Object o, int runs, int warmupRuns) {
        DemoLog.log("[serializer]: serializing");    
    }


    public void deserializeSmall4(int runs, int warmupRuns) {
        deserialize(new DemoObject.Small4(), runs, warmupRuns);
    }

    public void deserializeSmall8(int runs, int warmupRuns) {
        deserialize(new DemoObject.Small8(), runs, warmupRuns);
    }

    private void deserialize(Object o, int runs, int warmupRuns) {
        DemoLog.log("[deserializer]: deserializing");    
    }

}
