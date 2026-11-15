# Not in the book: the GNOME 51 release, built with meson as README.md
# describes.
build() {
    mkdir build
    cd build
    # mathcat=false: MathML support builds MathCAT, a Rust subproject whose
    # crates cargo would fetch from crates.io; builds are offline. spiel is experimental and has no
    # recipe. setup itself checks, through Python, for the Atspi overrides,
    # GTK 3, PyGObject and dasbus.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D mathcat=false \
        -D spiel=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
