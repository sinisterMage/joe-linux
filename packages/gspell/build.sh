build() {
    mkdir gspell-build
    cd gspell-build
    # The book's options, plus the introspection data and Vala bindings
    # stated, and neither the tests nor the gspell-app demo built.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gobject_introspection=true \
        -D vapi=true \
        -D gspell_app=false \
        -D gtk_doc=false \
        -D tests=false \
        -D install_tests=false
    ninja
}

package() {
    cd gspell-build
    DESTDIR="$DESTDIR" ninja install
}
