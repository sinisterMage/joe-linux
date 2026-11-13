build() {
    mkdir build
    cd build
    # No --wrap-mode=nofallback: ministream comes from subprojects/ministream
    # inside the tarball. nodownload still forbids fetching anything.
    # examples would build and install the demo application.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D introspection=enabled \
        -D vapi=true \
        -D profiling=false \
        -D documentation=false \
        -D tests=false \
        -D examples=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
