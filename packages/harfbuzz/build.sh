build() {
    mkdir build
    cd build
    # Built before cairo, as the book orders it (cairo's own recommended
    # dependencies come first), so there is no libharfbuzz-cairo and hb-view.
    # Graphite2 supplies the complementary shaper LibreOffice requires.
    # Chafa has no recipe. The GLFW GPU demo stays off: GLFW's libdecor
    # dependency brings GTK/Pango back to HarfBuzz, creating a cycle.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D glib=enabled \
        -D gobject=enabled \
        -D introspection=enabled \
        -D freetype=enabled \
        -D icu=enabled \
        -D png=enabled \
        -D zlib=enabled \
        -D graphite2=enabled \
        -D cairo=disabled \
        -D chafa=disabled \
        -D gpu_demo=disabled \
        -D docs=disabled \
        -D tests=disabled \
        -D benchmark=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
