# Not in the book: the newest upstream release, built with meson as its
# README says. It installs only headers and spice-protocol.pc.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
