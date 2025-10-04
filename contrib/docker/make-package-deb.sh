#!/bin/bash
# This script is intended to be run from the packager container for RPi5.
# It builds Asterisk and creates a DEB package instead of RPM.
# Please see the README.md file for more information on how this script is used.
#
set -ex
[ -n "$1" ]
VERSION="$1"

mkdir -p /opt

# move into the application directory where Asterisk source exists
cd /application

# strip the source of any Git-isms
rsync -av --exclude='.git' . /tmp/application

# move to the build directory and build Asterisk
cd /tmp/application

# Configure Asterisk with bundled pjproject for better ARM compatibility
./configure --with-pjproject-bundled

# Build menuselect
cd menuselect
make menuselect
cd ..
make menuselect-tree

menuselect/menuselect --check-deps menuselect.makeopts

# Do not include sound files. You should be mounting these from an external
# volume.
sed -i -e 's/MENUSELECT_MOH=.*$/MENUSELECT_MOH=/' menuselect.makeopts
sed -i -e 's/MENUSELECT_CORE_SOUNDS=.*$/MENUSELECT_CORE_SOUNDS=/' menuselect.makeopts
sed -i -e 's/MENUSELECT_EXTRA_SOUNDS=.*$/MENUSELECT_EXTRA_SOUNDS=/' menuselect.makeopts

# Build it!
make all install DESTDIR=/tmp/installdir

rm -rf /tmp/application
cd /build

# Use the Fine Package Management system to build us a DEB without all that
# reeking effort.
fpm -t deb -s dir -n asterisk-rpi5 --version "$VERSION" \
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
    --depends libmariadb3 \
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

chown -R --reference /application/contrib/docker/make-package-deb.sh .
