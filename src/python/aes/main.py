import base64

from Crypto import Random
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2

# Global variables.
SALT_LENGTH = 16
PASSWORD_LENGTH = 16
BLOCK_SIZE = 16
SALT = "**Salt Bea moves here**".encode("utf8")


# AES 256 encryption/decryption using pycrypto library as workload.
def get_private_key(password, salt):
    kdf = PBKDF2(password, salt, 64, 1000)
    key = kdf[:32]
    return key


def pad(s):
    return s + (BLOCK_SIZE - len(s) % BLOCK_SIZE) * chr(BLOCK_SIZE - len(s) % BLOCK_SIZE).encode("utf8")


def encrypt(raw, password):
    private_key = get_private_key(password, SALT)
    raw = pad(raw)
    iv = Random.new().read(AES.block_size)
    cipher = AES.new(private_key, AES.MODE_CBC, iv)
    return base64.b64encode(iv + cipher.encrypt(raw))


def unpad(s):
    return s[:-ord(s[len(s) - 1:])]


def decrypt(enc, password):
    private_key = get_private_key(password, SALT)
    enc = base64.b64decode(enc)
    iv = enc[:16]
    cipher = AES.new(private_key, AES.MODE_CBC, iv)
    return unpad(cipher.decrypt(enc[16:]))


# Main function.
def main(args):
    output = {}

    # Preprocess data.
    message = args['message'].encode("utf8")
    password = args['password'].encode("utf8")

    if args['type'] == "encrypt":
        # Encrypt message.
        output['result'] = encrypt(message, password).decode("utf8")
    elif args['type'] == "decrypt":
        # Decrypt message.
        output['result'] = decrypt(message, password).decode("utf8")
    else:
        # Wrong selection.
        output['result'] = "Wrong selection! Possible: encrypt or decrypt!"

    return output
