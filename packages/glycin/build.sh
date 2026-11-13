build() {
    mkdir build
    cd build
    # The book runs "cargo vendor" first; meson gives cargo a home of its
    # own under the build directory and cargo fetches the same crates there
    # (Cargo.lock pins them), so that step is not needed.
    # - libglycin-gtk4 is the separate glycin-gtk4 recipe, built after GTK.
    # - loaders: PNG, JPEG, GIF, TIFF, WebP and the like (glycin-image-rs),
    #   JPEG XL (GNOME's wallpapers) and SVG. HEIF needs libheif, which does
    #   not exist here.
    # - capi_docs needs gi-docgen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D libglycin=true \
        -D libglycin-gtk4=false \
        -D glycin-loaders=true \
        -D loaders=glycin-image-rs,glycin-jxl,glycin-svg \
        -D glycin-thumbnailer=true \
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
