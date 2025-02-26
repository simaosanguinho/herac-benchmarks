# Copyright (c) 2024, Oracle and/or its affiliates. All rights reserved.
set(TEST_NAME "simple-http")
file(GLOB_RECURSE NATIVE_IMAGE_SOURCES *.gradle src/*)

add_custom_target(test-apps-common-java-${TEST_NAME} DEPENDS musl native/nativeCompile/${TEST_NAME})
add_gradle_native_image(${TEST_NAME} SOURCES ${NATIVE_IMAGE_SOURCES})
graalos_add_test_app(test-apps-common-java-${TEST_NAME})
