build() {
    mkdir build
    cd build
    # Built before cairo, as the book orders it (cairo's own recommended
    # dependencies come first), so there is no libharfbuzz-cairo and hb-view.
    # graphite2 (recommended, wanted by texlive and LibreOffice only), chafa
    # and the glfw/glew GPU demo have no recipes.
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
        -D graphite2=disabled \
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
