package com.demo_ni_osd;

import java.util.Random;

public class DemoObject {

    public static final Random rng = new Random();

    public static class Small4 {
        public int field1 = rng.nextInt();
        public int field2 = rng.nextInt();
        public int field3 = rng.nextInt();
        public int field4 = rng.nextInt();
    }

    public static class Small8 {
        public int field1 = rng.nextInt();
        public int field2 = rng.nextInt();
        public int field3 = rng.nextInt();
        public int field4 = rng.nextInt();
        public int field5 = rng.nextInt();
        public int field6 = rng.nextInt();
        public int field7 = rng.nextInt();
        public int field8 = rng.nextInt();
    }
}
