build() {
    mkdir bld
    cd bld
    # The book's options, plus everything it leaves to detection stated: the
    # introspection data and Vala bindings that GEGL and GIMP build on, and
    # Little CMS. The HTML reference (the book copies it by hand) and the
    # gi-docgen one are not built. SIMD variants are compiled for each
    # x86-64 level and chosen at run time.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-gir=true \
        -D enable-vapi=true \
        -D with-lcms=enabled \
        -D with-docs=false \
        -D gi-docgen=disabled
    ninja
}

package() {
    cd bld
    DESTDIR="$DESTDIR" ninja install
}
