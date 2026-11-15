# Not in the book: the newest upstream release (tag v1.9.4), built as its
# README says.
prepare() {
    # A tag snapshot carries no configure script. The version would come
    # from git, which this tree is not; give it the release.
    export EROFS_UTILS_VERSION="$PKG_VERSION"
    autoreconf -fiv
}

build() {
    export EROFS_UTILS_VERSION="$PKG_VERSION"
    # Upstream leaves these off by default and they stay off: building
    # images from S3 and OCI registries (libcurl, openssl, libxml2, json-c),
    # ublk and NBD mounting (libnl3), the fanotify backend. Not available:
    # Intel QPL, SELinux labels.
    ./configure --prefix=/usr \
        --enable-lz4 \
        --enable-lzma \
        --with-zlib \
        --with-libdeflate \
        --with-libzstd \
        --with-uuid \
        --enable-fuse \
        --enable-multithreading \
        --disable-s3 \
        --disable-oci \
        --disable-ublk \
        --disable-fanotify \
        --without-libcurl \
        --without-openssl \
        --without-libxml2 \
        --without-json-c \
        --without-libnl3 \
        --with-xxhash \
        --without-qpl \
        --without-selinux
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
