# Not in the book: the newest upstream release, built with meson as its
# INSTALL says.
build() {
    mkdir build
    cd build
    # The SSH server half is proprietary and not in the tarball.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D with_server=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
