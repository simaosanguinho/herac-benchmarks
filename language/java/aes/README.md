### Description

The Java app with operation of encryption/decryption of given messages and password.

### Language

Written in **Java**.

### Build tool

Build with **Gradle**.

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
