package com.demo_ni_osd;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

public class DemoObjects {

    public static final Random rng = new Random();

    public static String randomStr(int size) {
        byte[] bytes = new byte[size];
        rng.nextBytes(bytes);
        return new String(bytes);
    }

    public static class RInt4 {
        public int field1 = rng.nextInt();
        public int field2 = rng.nextInt();
        public int field3 = rng.nextInt();
        public int field4 = rng.nextInt();
    }

    public static class RInt8 {
        public int field1 = rng.nextInt();
        public int field2 = rng.nextInt();
        public int field3 = rng.nextInt();
        public int field4 = rng.nextInt();
        public int field5 = rng.nextInt();
        public int field6 = rng.nextInt();
        public int field7 = rng.nextInt();
        public int field8 = rng.nextInt();
    }

    public static class RString64 {
        public String field1 = randomStr(64);
    }

    public static class RString128 {
        public String field1 = randomStr(128);
    }

    public static class AList4 {
        public List<RInt4> field = new ArrayList<>(4);

        public AList4() {
            field.add(new RInt4());
            field.add(new RInt4());
            field.add(new RInt4());
            field.add(new RInt4());
        }
    }

    public static class AList8 {
        public List<RInt8> field = new ArrayList<>(8);

        public AList8() {
            field.add(new RInt8());
            field.add(new RInt8());
            field.add(new RInt8());
            field.add(new RInt8());
        }
    }

    public static class HMap4 {
        public Map<String, RInt4> field = new HashMap<>(4);

        public HMap4() {
            field.put(randomStr(4), new RInt4());
            field.put(randomStr(4), new RInt4());
            field.put(randomStr(4), new RInt4());
            field.put(randomStr(4), new RInt4());
        }
    }

    public static class HMap8 {
        public Map<String, RInt8> field = new HashMap<>(8);

        public HMap8() {
            field.put(randomStr(8), new RInt8());
            field.put(randomStr(8), new RInt8());
            field.put(randomStr(8), new RInt8());
            field.put(randomStr(8), new RInt8());
        }
    }
}
