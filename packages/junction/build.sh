# Not in the book: the newest upstream release (a tag; the GitHub releases
# page stops at 1.5.0), built with its meson files (the README describes
# only Flatpak builds). Upstream
# publishes no checksum for either archive.
prepare() {
    tar -xf "$SOURCES/troll-37b53b29db0b6496f31e13c7f843100db31c9eb1.tar.gz" \
        -C troll --strip-components=1 --no-same-owner --no-same-permissions
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
