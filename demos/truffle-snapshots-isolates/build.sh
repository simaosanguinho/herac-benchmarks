# Assuming that the benchmarks directory is a sibling to Argo
GRAALVM_HOME=../../../argo/resources/graalvm-ee-java11-22.1.0

$GRAALVM_HOME/bin/javac JsLauncherSnapshotsIsolates.java
$GRAALVM_HOME/bin/native-image -H:Name=js -H:+AuxiliaryEngineCache -H:ReservedAuxiliaryImageBytes=1073741824 -Dorg.graalvm.launcher.home="$GRAALVM_HOME" --language:js JsLauncherSnapshotsIsolates

# This script will generate executable "js"
