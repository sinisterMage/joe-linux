build() {
    mkdir build
    cd build
    # No libthai and no sysprof in joe Linux.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D introspection=enabled \
        -D fontconfig=enabled \
        -D freetype=enabled \
        -D cairo=enabled \
        -D xft=enabled \
        -D libthai=disabled \
        -D sysprof=disabled \
        -D man-pages=true \
        -D documentation=false \
        -D build-testsuite=false \
        -D build-examples=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
