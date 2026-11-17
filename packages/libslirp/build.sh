# Following the book's libslirp page.
prepare() {
    # The archive is a plain export of the tag: give git-version-gen the
    # version, so that it does not ask git, which would describe whatever
    # repository happens to enclose the build directory.
    echo "$PKG_VERSION" > .tarball-version
}

build() {
    mkdir -p build
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
