## Description

The script with operation of encryption/decryption of given messages with randomly generated password.

### Language

Written in **JavaScript**.

### Build tool

Without build tool.

### Functions

```python
def aes(op_type, message, password):
    if op_type == "encrypt":
        # Encrypt message.
        return encrypt(message, password)
    if op_type == "decrypt"
        # Decrypt message.
        return decrypt(message, password)
```
