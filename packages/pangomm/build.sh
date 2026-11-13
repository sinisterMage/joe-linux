build() {
    mkdir build
    cd build
    # The book builds with the defaults. Stated here: the tarball's generated
    # sources are used as they are, and no Doxygen documentation.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
