# Not in the book: the newest upstream release, built with meson as its
# INSTALL says.
build() {
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja -C build
}

package() {
    # With DESTDIR set, meson does not run glib-compile-schemas.
    DESTDIR="$DESTDIR" ninja -C build install
}
