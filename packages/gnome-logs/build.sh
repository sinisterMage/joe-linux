# Following the book's gnome-logs page, which carries 45.0 (upstream has
# released 50.0 since).
build() {
    mkdir build
    cd build
    # man: the book leaves it off; xsltproc and the DocBook stylesheets have
    # recipes, so the manual page is made.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D man=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
