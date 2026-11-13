build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D introspection=enabled \
        -D vapi=true \
        -D documentation=false \
        -D sysprof=false \
        -D build-testsuite=false \
        -D install-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
