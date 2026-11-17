# Following the book's totem-pl-parser page, with the recommended libarchive
# and libgcrypt, and uchardet, required explicitly.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-libarchive=yes \
        -D enable-libgcrypt=yes \
        -D enable-uchardet=yes \
        -D enable-gtk-doc=false \
        -D introspection=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
