# There is no book page. Decibels versions on its own; 49.6.1 is the newest
# stable release and is what GNOME 51 ships. Upstream's meson options at
# their defaults.
build() {
    mkdir build
    cd build
    # --wrap-mode=nodownload: the tarball names blueprint-compiler as a
    # subproject to fetch when missing. The type definitions tsc checks
    # against (gi-types) are in the tarball.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
