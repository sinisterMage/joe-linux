build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=enabled \
        -D nls=enabled \
        -D man=true \
        -D documentation=disabled \
        -D tests=false \
        -D conformance=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
