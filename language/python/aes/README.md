### Description

The script with operation of encryption/decryption of given messages and password.

### Language

Written in **Python**.

### Build tool

Without build tool.

### Prerequisite

```commandline
pip3 install PyCryptodome
```

### Functions

```python
def aes(type, message, password):
    if type == "encrypt":
        # Encrypt message.
        return encrypt(message, password)
    if type == "decrypt"
        # Decrypt message.
        return decrypt(message, password)
```
