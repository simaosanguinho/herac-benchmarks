### Description

The script that downloads image content, creates an image out of it, sends it to a remote storage, and returns the image
name back to the user.

### Language

Written in **Python**.

### Build tool

Without build tool.

### Prerequisite

```commandline
pip3 install requests
pip3 install Pillow
```

### Functions

```python
def thumbnail(img_url):
    # Pull image via image url.
    img_content = pull(img_url)
    # Create image.
    img = create_image(img_content)
    # Send image to remote storage.
    send_image(img)
    # Return image name back to user.
    return img.name
```
