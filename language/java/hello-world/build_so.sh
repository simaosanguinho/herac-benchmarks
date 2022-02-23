./gradlew clean shadowJar assemble

# Collect possible reflections
$JAVA_HOME/bin/java -agentlib:native-image-agent=config-output-dir=src/main/resources/META-INF/native-image \
  -cp build/libs/hello-world-1.0-all.jar \
  GuestLauncher com.hello_world.HelloWorld "{\"name\":\"Sutao\"}"
> /dev/null 2>&1

$JAVA_HOME/bin/native-image --no-fallback -cp build/libs/hello-world-1.0-all.jar\
  -DGraalVisorGuest=true \
  -Dcom.oracle.svm.graalvisor.libraryPath=build/resources/main/com.oracle.svm.graalvisor.headers \
  --initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
  -H:ConfigurationFileDirectories="src/main/resources/META-INF/native-image" \
  -H:+ReportExceptionStackTraces\
  --shared -H:Name=libhelloworld

#cp libhelloworld.so ../../../../argo/lambda-proxy/src/scripts/
