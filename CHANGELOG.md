# v2

## New features

- thecodingmachine/php image now has a "slim" variant that does not contain any extension but that can be used
  to [build the extensions very easily](https://github.com/thecodingmachine/docker-images-php/blob/dfdaa984f0fcc3d66a1b9fef5a6643582deb4d0d/README.md#compiling-extensions-in-the-slim-image).

## Breaking changes

- PHP 7.1 base image is now **Debian Stretch**
- Dropped Node 6 images

## New extensions

- Imagick

## Organization

The project layout has been deeply changed. There is now only one branch for all the PHP versions.
Each extension now has its own installation script in the `/extensions/core` directory with symlinks for the 
extensions in the `/extensions/7.1` and `/extensions/7.2` directory based on the targeted PHP version.
