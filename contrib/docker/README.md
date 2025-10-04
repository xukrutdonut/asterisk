# Building Asterisk into a Docker Container Image

> **Note for Raspberry Pi 5 Users:** If you're building for Raspberry Pi 5 (ARM64), please see [README.rpi5.md](README.rpi5.md) for specific instructions.

The following set of steps should leave you with a Docker container that
is relatively small, built from your local checked out source, and even
provides you with a nice little RPM too!

## Architecture Support

- **x86_64 (default):** CentOS 7 based, builds RPM packages
- **ARM64/aarch64 (Raspberry Pi 5):** Debian based, builds DEB packages (see [README.rpi5.md](README.rpi5.md))

## Build the package container image
Build the package container image. This uses FPM[1] so no `spec` files and
such are necessary.
```
docker build --pull -f contrib/docker/Dockerfile.packager -t asterisk-build .
```

## Build your Asterisk RPM from source
Build the Asterisk RPM from the resulting container image.
```
docker run -ti \
    -v $(pwd):/application:ro \
    -v $(pwd)/out:/build \
    -w /application asterisk-build \
    /application/contrib/docker/make-package.sh 13.6.0
```
> **NOTE**: If you need to build this on a system that has SElinux enabled
> you'll need to use the following command instead:
> ```
> docker run -ti \
>     -v $(pwd):/application:Z \
>     -v $(pwd)/out:/build:Z \
>     -w /application asterisk-build \
>     /application/contrib/docker/make-package.sh 13.6.0
> ```

## Create your Asterisk container image
Now create your own Asterisk container image from the resulting RPM.
```
docker build --rm -t madsen/asterisk:13.6.0-1 -f contrib/docker/Dockerfile.asterisk .
```

# References
[1] https://github.com/jordansissel/fpm
