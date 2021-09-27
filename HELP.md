# HELP 

## Need help

* [ ] Script who test all available extensions in one pass
* [ ] BuildKit is now use without trouble, for extend it, use of docker buildx bake may helpful
* [ ] We need lighten the images 
* [ ] Link and document one tool who help create packaged app with the slim image

## Tips

### How to test extensions available

* Build the slim image
* Run it with docker and try extensions with follow commands 
  ```bash
  docker run -it --rm thecodingmachine/php:8.1-v4-slim-apache sudo bash
  apt-get update
  apt-cache search --names-only php8.1-zip
  ```
* Pay attention of extensions installed by pickle (not listed on apt repo)

Some links with information updated : 
* [One list of php extensions supported in PHP 8.0](https://blog.remirepo.net/post/2020/09/21/PHP-extensions-status-with-upcoming-PHP-8.0)

### Compare list extensions between versions

```bash 
diff -q ./extensions/core ./extensions/8.0
```