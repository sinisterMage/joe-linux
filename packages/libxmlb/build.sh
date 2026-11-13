build() {
    mkdir build
    cd build
    # No libstemmer in joe Linux.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtkdoc=false \
        -D introspection=true \
        -D stemmer=false \
        -D cli=true \
        -D lzma=enabled \
        -D zstd=enabled \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
