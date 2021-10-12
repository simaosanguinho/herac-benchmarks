### Description

The script with operation of hashing file via file url.

### Language

Written in **JavaScript**.

### Build tool

Without build tool.

### Functions

```python
def file_hash(file_url):
    # Pull file via file url.
    file_content = pull(file_url)
    # Hash file.
    return hash(file_content)
```
