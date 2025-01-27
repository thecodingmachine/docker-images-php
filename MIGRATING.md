# Migrating from v4 to v5 images

FIXME : review the changes 

This version is an intermediate one to wait the v6 who expected many more changes (but we wait for it too long time). 
v5 is mostly fully compatible with v4, the main issue that may happen are related to the OS version (for the most case, that is not relevant)

Important changes:
- v4 images are based on **Ubuntu 20.04**. v5 images are based on **Ubuntu 24.04**.
- Removing of all unsupported version (not maintenance/security support : that is still possible to use the old tags/force manually the rebuild)
- Default blackfire version is now the version 2

# Migrating from v3 to v4 images

Important changes:

- v3 images are based on **Ubuntu 18.04**. v4 images are based on **Ubuntu 20.04**.
- Internally, the image will attempt to set up extensions / parameters on container startup (in the image entry point),
  but also when PHP is run. This should help alleviate a part of the problems when the entrypoint is overloaded by the
  user.

# Migrating from v2 to v3 images

Important changes:

- v2 images are based on a Debian Stretch. v3 images are based on **Ubuntu 18.04**.
- Internally, v3 images are built from the [Ondrej PPA](https://launchpad.net/%7Eondrej/+archive/ubuntu/php/+index?batch=75&memo=75&start=75).
  This is a radical change from v2 that was built from the official PHP Docker image.
  As a result, the v3 image do not have PECL installed, nor a build environment. This makes the v3 images ~200MB lighter. 

Changes in extensions:

- The following extensions are now **enabled by default**: `calendar exif pcntl shmop sockets sysvmsg sysvsem sysvshm wddx zip`
- The `sqlite3` extension was previously enabled by default, but must now be enabled manually
