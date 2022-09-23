[<- Main documentation](../README.md)

{{ $image := .Orbit.Images }}
# Platforms

## Support `amd` and `arm`

Both platform are supported on these images but [some limitations exist for `arm` build](#arm).
This project try to keep old versions active on ours build but : 
* You may experience some issue with them (less testing, and it's more difficult to support)
* In next version (V5), these images may have less default features (probably the fat version maybe no more updated or less than supported one)
* If you want to ensure more support on deprecated one, you can send your PR and/or open an issue to suggest solutions

So it's only to allow you to upgrade to the next supported version an old project.  

## AMD

It's the common platform of maintainer, so there is more tests on it.

## ARM

### ARM Limitations

This version have some limitations :
* On Gitlab-action, arm builds require more time to test/build (around x8). So to avoid too long deployments, some limitations exist on arm build (as hotfix : we will try to find a solution for that)
* *ev*, *rdkafka*, *snmp* and *swoole* are not available in all `ARM64` images : you can compile them manually but each require around 1 hours of build time if you did that with emulation of arm.

### ARM and `macos` Performances

We don't have yet any relevant information about that for instance. For sure, if you use it onto raspberry pi4 (arm64), it will be less efficient than image amd onto intel i7. But to compare M1/M2 than i7, it's more complex to test. Please open an issue if you have more information about that, it may be helpful for the community.

Note also, onto `macos` computers, your filesystems is encrypted by default. It's better for security but have also a cost for compute many files in the container. This issue is not related to images and platform. You will have exactly the same issue with `fscrypt` onto linux amd system. To avoid that, there is some solutions suggested by docker (please refer to this own documentation), you may also synchronise your files onto RAM fs, use an unencrypted fs for that (but if you encrypt, you may have good raisons for that !), or compute less files (some frameworks compute lot of files, like symfony : if you activate the caching features, you will avoid major part of the trouble).

## How to use in yours platforms ?

In local storage, docker not support yet multiplatform. So when you pull an image, your local docker will fetch automatically the right version who fit for your processor. If he do not find it, he will display a warning and try to emulate with another (yes, he can do that, but it's very inefficient !). Per example, our build of `amd` take less than 10 minute for each variant, it's take more than 1 hour for the same as `arm` (because we emulate `arm` onto an `amd` processor).

You may have to specify the platform you want if you need to build an image or make some tests :
* For arm : `docker pull --platform linux/arm64 thecodingmachine/php:{{ .Orbit.Images.php_version }}-v4-cli && docker run -it --rm --platform linux/arm64 thecodingmachine/php:{{ .Orbit.Images.php_version }}-v4-cli -- php -i`
* For amd : `docker pull --platform linux/amd64 thecodingmachine/php:{{ .Orbit.Images.php_version }}-v4-cli && docker run -it --rm --platform linux/amd64 thecodingmachine/php:{{ .Orbit.Images.php_version }}-v4-cli -- php -i`
* Per default, docker will try to pull/run an image who match with your real platform (you don't need to specify witch platform you want in any regulars cases). 
