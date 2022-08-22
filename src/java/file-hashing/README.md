### Description

The Java app with operation of hashing file via file url.

### Language

Written in **Java**.

### Build tool

Built with **Gradle**.

### Functions

```python
def file_hash(file_url):
    # Pull file via file url.
    file_content = pull(file_url)
    # SHA1 and MD5 of file.
    return sha1(file_content), md5(file_content)
```
