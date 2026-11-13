build() {
    mkdir build
    cd build
    # The book's libdbus=auto finds dbus, which is always present here. The
    # Python bindings need SWIG; liburing does not exist.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D libdbus=enabled \
        -D json-c=enabled \
        -D openssl=enabled \
        -D keyutils=enabled \
        -D python=disabled \
        -D liburing=disabled \
        -D docs=false \
        -D docs-build=false \
        -D examples=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
