build() {
    mkdir build
    cd build
    # Only libglycin-gtk4, linked against the installed libglycin; the
    # library, the loaders and the thumbnailer are the glycin recipe.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D libglycin=false \
        -D libglycin-gtk4=true \
        -D glycin-loaders=false \
        -D glycin-thumbnailer=false \
        -D introspection=true \
        -D vapi=true \
        -D capi_docs=false \
        -D python_tests=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
