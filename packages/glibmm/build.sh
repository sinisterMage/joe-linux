build() {
    mkdir bld
    cd bld
    # The book builds with the defaults. Stated here: the tarball's generated
    # sources are used as they are (maintainer-mode), no documentation
    # (Doxygen does not exist) and no example programs.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true \
        -D build-examples=false \
        -D build-mmgir=false
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
