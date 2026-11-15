# Every installed path carries the API version (gtkmm-3.0, gdkmm-3.0), so it
# does not collide with gtkmm4 (gtkmm-4.0).
build() {
    mkdir gtkmm3-build
    cd gtkmm3-build
    # The book builds with the defaults. Stated here: the tarball's generated
    # sources are used as they are, no Doxygen documentation, and neither the
    # demo (it would install gtkmm-demo) nor the tests. The atkmm and X11
    # parts of the API are built, as by default.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D maintainer-mode=false \
        -D build-documentation=false \
        -D build-deprecated-api=true \
        -D build-atkmm-api=true \
        -D build-x11-api=true \
        -D build-demos=false \
        -D build-tests=false
    ninja
}

package() {
    cd gtkmm3-build
    DESTDIR="$DESTDIR" ninja install
}
