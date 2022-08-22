### Description

The Java app downloads image content, creates an image out of it, sends it to a remote storage, and returns the image
name back to the user.

### Language

Written in **Java**.

### Build tool

Built with **Gradle**.

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
