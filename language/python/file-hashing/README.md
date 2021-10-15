### Description

The script with operation of hashing file via file url.

### Language

Written in **Python**.

### Build tool

Without build tool.

### Functions

```python
def file_hash(file_url):
    # Pull file via file url.
    file_content = pull(file_url)
    # Create tmp file.
    file = create_tmp_file(file_content)
    # SHA1 and MD5 of file.
    return sha1(file_content), md5(file_content)
```
