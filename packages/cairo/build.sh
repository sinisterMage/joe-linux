build() {
    mkdir build
    cd build
    # Everything the book recommends is enabled explicitly: fontconfig and
    # freetype fonts, cairo-gobject (glib) and the Xlib and XCB surfaces.
    # No lzo and no libspectre; symbol-lookup would link the test helpers
    # against binutils' libbfd.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D fontconfig=enabled \
        -D freetype=enabled \
        -D png=enabled \
        -D zlib=enabled \
        -D glib=enabled \
        -D xlib=enabled \
        -D xcb=enabled \
        -D lzo=disabled \
        -D spectre=disabled \
        -D symbol-lookup=disabled \
        -D gtk2-utils=disabled \
        -D tests=disabled \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
