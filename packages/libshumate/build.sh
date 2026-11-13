build() {
    mkdir build
    cd build
    # The book's options, plus:
    # - gir (which gnome-maps needs) and vapi as upstream's defaults, stated
    #   so that they do not depend on the build root.
    # - sysprof does not exist here; --wrap-mode=nodownload keeps meson from
    #   fetching it (and gi-docgen) as a subproject.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D gir=true \
        -D vapi=true \
        -D gtk_doc=false \
        -D demos=false \
        -D sysprof=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
