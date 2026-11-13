build() {
    # Where the fence file is created when memfd_create() is not available.
    # Without this configure takes the first of /run/shm, /dev/shm, /var/tmp and
    # /tmp that exists in the build root.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libxshmfence-$PKG_VERSION" \
        --with-shared-memory-dir=/dev/shm
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
