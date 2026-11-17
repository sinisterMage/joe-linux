# Not in the book: the newest upstream release (GNOME 51), built with meson
# as its README says.
build() {
    mkdir build
    cd build
    # camera is declared but unused by this release (camera support is
    # always built).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default \
        -D goa=true \
        -D manpage=true \
        -D docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
