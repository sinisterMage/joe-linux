# Following the book's gtksourceview4 page. 4.8.4 is the last release of the
# GTK 3 series; it installs beside gtksourceview5. Meld needs it.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D gir=true \
        -D vapi=true \
        -D glade_catalog=false \
        -D install_tests=false \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
