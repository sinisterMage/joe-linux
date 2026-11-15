# The 2.66 series of glibmm, the API (glibmm-2.4, giomm-2.4) that gtkmm 3 is
# built on. Every installed path carries the API version, so it does not
# collide with glibmm (glibmm-2.68).
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
        -D build-examples=false
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
