# Python+Packages Embedding Demo with GraalVM based on JDK 21

This repository contains a demo Python+packages embedding in Java with GraalVM based on JDK 21.

GraalVM distributions based on JDK 21+ have a different way of using Truffle-related packages compared to GraalVM with JDK 17 and older.
The "[Truffle Unchained](https://medium.com/graalvm/truffle-unchained-13887b77b62c)" update offers Truffle languages and polyglot embeddings as separate dependencies to be used in Gradle or Maven projects.
This changes the way Truffle benchmarks are packaged with recent GraalVM versions.

The goal of this demo is to show how Python+packages benchmarks can be built and compiled into native images.

This repository is heavily inspired by the official [graalpy-custom-venv-guide](https://github.com/graalvm/graal-languages-demos/tree/main/graalpy/graalpy-custom-venv-guide).

## Set Up

Make sure to set `JAVA_HOME` to a GraalVM distribution based on JDK 21.

Download [GraalPy standalone distribution](https://github.com/oracle/graalpython/releases/).

Execute:
```
$ cd path/to/graalpy-standalone/bin
$ ./graalpy -m venv myenv
$ cd myenv/bin
$ . ./activate
$ python --version    # just to make sure
$ pip install numpy==1.23.5    # this might take some time
```

## Usage

Use the following commands to build and run the application:

* `./gradlew build` build using javac
* `venv=/path/to/myenv ./gradlew run` to run the Main application
* `./gradlew nativeCompile` to build a native-image 
* `venv=/path/to/myenv ./gradlew nativeRun` to run the native image

**Important Note**: if using this demo to update existing Hydra benchmarks for a new JDK version of GraalVM, make sure to keep and test engine/context options from `graalvisor-lib`.
