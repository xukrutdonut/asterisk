# Multi-stage Dockerfile for building Asterisk on Raspberry Pi 5 (ARM64/aarch64)
# This enables building with: docker compose up -d --build

# Stage 1: Build environment
FROM debian:bookworm AS builder

LABEL maintainer="Asterisk Development Team"
LABEL description="Build environment for Asterisk on Raspberry Pi 5 (ARM64)"

ENV DEBIAN_FRONTEND=noninteractive
ENV REFRESHED_AT=2024-01-15

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    # Basic build tools
    build-essential \
    pkg-config \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    wget \
    curl \
    git \
    rsync \
    # Asterisk dependencies from install_prereq
    libedit-dev \
    libjansson-dev \
    libsqlite3-dev \
    uuid-dev \
    libxml2-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libogg-dev \
    libvorbis-dev \
    libasound2-dev \
    portaudio19-dev \
    libcurl4-openssl-dev \
    xmlstarlet \
    bison \
    flex \
    libpq-dev \
    unixodbc-dev \
    libneon27-dev \
    libgmime-3.0-dev \
    liblua5.2-dev \
    liburiparser-dev \
    libxslt1-dev \
    libssl-dev \
    libmysqlclient-dev \
    libbluetooth-dev \
    libradcli-dev \
    freetds-dev \
    libjack-jackd2-dev \
    bash \
    libcap-dev \
    libsnmp-dev \
    libiksemel-dev \
    libcorosync-common-dev \
    libcpg-dev \
    libcfg-dev \
    libnewt-dev \
    libpopt-dev \
    libical-dev \
    libspandsp-dev \
    libresample1-dev \
    libc-client2007e-dev \
    binutils-dev \
    libsrtp2-dev \
    libgsm1-dev \
    doxygen \
    graphviz \
    zlib1g-dev \
    libldap2-dev \
    libcodec2-dev \
    libfftw3-dev \
    libsndfile1-dev \
    libunbound-dev \
    # For building DEB packages
    dpkg-dev \
    debhelper \
    dh-make \
    fakeroot \
    lintian \
    ruby \
    ruby-dev \
    rubygems \
    # For bundled pjproject
    bzip2 \
    patch \
    # Additional tools
    subversion \
    && rm -rf /var/lib/apt/lists/*

# Install FPM (Effing Package Management) for building packages
RUN gem install --no-document fpm

WORKDIR /tmp/application

# Copy the entire source tree
COPY . /tmp/application/

# Build Asterisk
ARG VERSION=20.0.0
RUN set -ex && \
    # Configure Asterisk with bundled pjproject for better ARM compatibility
    ./configure --with-pjproject-bundled && \
    # Build menuselect
    cd menuselect && \
    make menuselect && \
    cd .. && \
    make menuselect-tree && \
    menuselect/menuselect --check-deps menuselect.makeopts && \
    # Do not include sound files. You should be mounting these from an external volume.
    sed -i -e 's/MENUSELECT_MOH=.*$/MENUSELECT_MOH=/' menuselect.makeopts && \
    sed -i -e 's/MENUSELECT_CORE_SOUNDS=.*$/MENUSELECT_CORE_SOUNDS=/' menuselect.makeopts && \
    sed -i -e 's/MENUSELECT_EXTRA_SOUNDS=.*$/MENUSELECT_EXTRA_SOUNDS=/' menuselect.makeopts && \
    # Build it!
    make all install DESTDIR=/tmp/installdir

# Create DEB package
RUN mkdir -p /build && \
    cd /build && \
    fpm -t deb -s dir -n asterisk-rpi5 --version "${VERSION}" \
    --architecture arm64 \
    --description "Asterisk PBX for Raspberry Pi 5" \
    --url "https://www.asterisk.org" \
    --license "GPLv2" \
    --depends libedit2 \
    --depends libjansson4 \
    --depends libsqlite3-0 \
    --depends uuid-runtime \
    --depends libxml2 \
    --depends libssl3 \
    --depends libspeex1 \
    --depends libspeexdsp1 \
    --depends libogg0 \
    --depends libvorbis0a \
    --depends libvorbisenc2 \
    --depends libasound2 \
    --depends libcurl4 \
    --depends libpq5 \
    --depends unixodbc \
    --depends libneon27 \
    --depends libgmime-3.0-0 \
    --depends liblua5.2-0 \
    --depends liburiparser1 \
    --depends libxslt1.1 \
    --depends libmysqlclient21 \
    --depends libbluetooth3 \
    --depends libradcli4 \
    --depends libsybdb5 \
    --depends libcap2 \
    --depends libsnmp40 \
    --depends libiksemel3 \
    --depends libcorosync-common4 \
    --depends libcpg4 \
    --depends libcfg7 \
    --depends libnewt0.52 \
    --depends libpopt0 \
    --depends libical3 \
    --depends libspandsp2 \
    --depends libresample1 \
    --depends libc-client2007e \
    --depends libsrtp2-1 \
    --depends libgsm1 \
    --depends zlib1g \
    --depends libldap-2.5-0 \
    --depends libcodec2-1.0 \
    --depends libfftw3-single3 \
    --depends libsndfile1 \
    --depends libunbound8 \
    -C /tmp/installdir etc usr var

# Stage 2: Runtime container
FROM debian:bookworm-slim

LABEL maintainer="Asterisk Development Team"
LABEL description="Asterisk runtime container for Raspberry Pi 5 (ARM64)"

ENV DEBIAN_FRONTEND=noninteractive
ENV REFRESHED_AT=2024-01-15

# Copy the built DEB package from builder stage
COPY --from=builder /build/*.deb /tmp/

# Install runtime dependencies and Asterisk DEB
RUN apt-get update && \
    apt-get install -y \
    # Core runtime dependencies
    libedit2 \
    libjansson4 \
    libsqlite3-0 \
    uuid-runtime \
    libxml2 \
    libssl3 \
    # Additional runtime libraries
    libspeex1 \
    libspeexdsp1 \
    libogg0 \
    libvorbis0a \
    libvorbisenc2 \
    libasound2 \
    portaudio19-dev \
    libcurl4 \
    libpq5 \
    unixodbc \
    libneon27 \
    libgmime-3.0-0 \
    liblua5.2-0 \
    liburiparser1 \
    libxslt1.1 \
    libmysqlclient21 \
    libbluetooth3 \
    libradcli4 \
    libsybdb5 \
    libcap2 \
    libsnmp40 \
    libiksemel3 \
    libcorosync-common4 \
    libcpg4 \
    libcfg7 \
    libnewt0.52 \
    libpopt0 \
    libical3 \
    libspandsp2 \
    libresample1 \
    libc-client2007e \
    libsrtp2-1 \
    libgsm1 \
    zlib1g \
    libldap-2.5-0 \
    libcodec2-1.0 \
    libfftw3-single3 \
    libsndfile1 \
    libunbound8 \
    # Install the Asterisk package
    && dpkg -i /tmp/*.deb || apt-get install -f -y \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*.deb

# Create necessary directories
RUN mkdir -p /var/run/asterisk \
    /var/log/asterisk \
    /var/lib/asterisk \
    /var/spool/asterisk \
    /etc/asterisk

# Expose standard Asterisk ports
# SIP: 5060/udp, 5061/tcp (TLS)
# RTP: 10000-20000/udp
# HTTP/HTTPS: 8088/tcp, 8089/tcp
# IAX2: 4569/udp
EXPOSE 5060/udp 5060/tcp 5061/tcp 8088/tcp 8089/tcp 4569/udp
EXPOSE 10000-20000/udp

# Set working directory
WORKDIR /var/lib/asterisk

# Run Asterisk in foreground with console
ENTRYPOINT ["/usr/sbin/asterisk"]
CMD ["-f", "-vvvvv", "-g", "-c"]
