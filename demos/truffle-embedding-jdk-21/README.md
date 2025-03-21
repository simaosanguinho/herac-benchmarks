# Polyglot Embedding Demo with GraalVM based on JDK 21

This repository contains a demo Truffle embedding in Java with GraalVM based on JDK 21.

GraalVM distributions based on JDK 21+ have a different way of using Truffle-related packages compared to GraalVM with JDK 17 and older.
The "[Truffle Unchained](https://medium.com/graalvm/truffle-unchained-13887b77b62c)" update offers Truffle languages and polyglot embeddings as separate dependencies to be used in Gradle or Maven projects.
This changes the way Truffle benchmarks are packaged with recent GraalVM versions.

The goal of this demo is to show how Truffle benchmarks can be built and compiled into native images.

This repository is heavily inspired by the official [polyglot-embedding-demo](https://github.com/graalvm/polyglot-embedding-demo).

## Usage

Make sure to set `JAVA_HOME` to a GraalVM distribution based on JDK 21.

Use the following commands to build and run the application:

* `gradle build` build using javac
* `gradle run` to run the Main application
* `gradle nativeCompile` to build a native-image 
* `gradle nativeRun` to run the native image
