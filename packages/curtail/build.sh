# Not in the book: the newest upstream release, built with meson as its
# README says. Upstream publishes no checksum for the release archive.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
