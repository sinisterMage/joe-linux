build() {
    mkdir build
    cd build
    # As in the book; the package has no options.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
