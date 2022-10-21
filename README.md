## Benchmarks

The benchmark's repository includes the list of all benchmarks. The documentation for each benchmark contains further
information. Benchmarks are split into different folders, based on language:

- (graalvisor and OpenWhisk) Java:
    - [gv/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-hello-world); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/cr-hello-world)
    - [gv/file-hashing](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-file-hashing); [cr/file-hashing](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/cr-file-hashing)
    - [gv/http-request](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-httprequest); [cr/http-request](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-httprequest)
    - [gv/video-processing](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-video-processing); [cr/video-processing](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-video-processing)
    - [gv/image-classification](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/gv-classify); [cr/image-classification](https://github.com/graalvm-argo/benchmarks/tree/main/src/java/cr-classify)
    
- (graalvisor and OpenWhisk) JavaScript:
    - [gv/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/gv-hello-world); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/cr-hello-world)
    - [gv/dynamic-html](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/gv-dynamic-html); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/cr-dynamic-html)
    - [gv/uploader](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/gv-uploader); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/cr-uploader)
    - [gv/thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/gv-thumbnail); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/javascript/cr-thumbnail)
    
- (graalvisor and OpenWhisk):
    - [gv/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-hello-world); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/cr-hello-world)
    - [gv/thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-thumbnail); [cr/thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/cr-thumbnail)
    - [gv/uploader](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-uploader); [cr/hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/cr-uploader)
    - [gv/compress](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-compress); [cr/compress](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/cr-compress)
    - [gv/video-processing](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-video-processing); [cr/video-processing](https://github.com/graalvm-argo/benchmarks/tree/main/src/python/gv-video-processing)
    
Some old benchmarks are also still available:

- (old) Java:
    - [aes](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/aes/README.md)
        - The **Java** app with operation of encryption/decryption of given messages and password.
    - [array-sorting](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/array-sorting/README.md)
        - The **Java** app with operation of merging two arrays into one sorted array as a workload.
    - [file-hashing](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/file-hashing/README.md)
        - The **Java** app with operation of hashing file via file url.
    - [hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/hello-world/README.md)
        - Simple Hello World **Java** app.
    - [reflection-call](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/reflection-call/README.md)
        - Simple **Java** app containing reflective call.
    - [thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/language/java/thumbnail/README.md)
        - The **Java** app downloads image content, creates an image out of it, sends it to a remote storage, and returns
          the image name back to the user.
- (old) Javascript:
    - [aes](https://github.com/graalvm-argo/benchmarks/tree/main/language/javascript/aes/README.md)
        - The script with operation of encryption/decryption of given messages with randomly generated password.
    - [array-sorting](https://github.com/graalvm-argo/benchmarks/tree/main/language/javascript/array-sorting/README.md)
        - The script with operation of merging two arrays into one sorted array as a workload.
    - [file-hashing](https://github.com/graalvm-argo/benchmarks/tree/main/language/javascript/file-hashing/README.md)
        - The script with operation of hashing file via file url.
    - [hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/language/javascript/hello-world/README.md)
        - Simple Hello World function.
    - [thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/language/javascript/thumbnail/README.md)
        - The script that downloads image content, creates an image out of it, sends it to a remote storage, and returns
          the image name back to the user.
- (old) Python:
    - [aes](https://github.com/graalvm-argo/benchmarks/tree/main/language/python/aes/README.md)
        - The script with operation of encryption/decryption of given messages and password.
    - [array-sorting](https://github.com/graalvm-argo/benchmarks/tree/main/language/python/array-sorting/README.md)
        - The script with operation of merging two arrays into one sorted array as a workload.
    - [file-hashing](https://github.com/graalvm-argo/benchmarks/tree/main/language/python/file-hashing/README.md)
        - The script with operation of hashing file via file url.
    - [hello-world](https://github.com/graalvm-argo/benchmarks/tree/main/language/python/hello-world/README.md)
        - Simple Hello World function.
    - [thumbnail](https://github.com/graalvm-argo/benchmarks/tree/main/language/python/thumbnail/README.md)
        - The script that downloads image content, creates an image out of it, sends it to a remote storage, and returns
          the image name back to the user.
