build() {
    mkdir build
    cd build
    # The book builds with the defaults. Stated here: the tarball's generated
    # sources are used as they are, no Doxygen documentation, and neither the
    # demo (it would install gtkmm4-demo) nor the tests.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true \
        -D build-demos=false \
        -D build-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
