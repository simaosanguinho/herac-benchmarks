package com.demo_ni_osd;

public interface DemoSerializer {
    public String serialize(Object o);
    public Object deserialize(String s, Class<?> clazz);
}
