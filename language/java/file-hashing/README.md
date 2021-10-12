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
    # Hash file.
    return hash(file_content)
```
