# The 2.46 series of pangomm, the API (pangomm-1.4) that gtkmm 3 is built on.
# Every installed path carries the API version, so it does not collide with
# pangomm (pangomm-2.48).
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
