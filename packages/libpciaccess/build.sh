build() {
    mkdir -p build
    cd build
    # Device names come from /usr/share/hwdata/pci.ids (the default, hwdata);
    # zlib lets the library read a gzip-compressed pci.ids as well.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D zlib=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
