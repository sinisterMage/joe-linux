build() {
    # The book's configuration, with GLib and the introspection data (which
    # the book has by having GLib built with it) stated. The GEGL bindings
    # are for GEGL 0.3 only, and the Doxygen and gperftools options stay off.
    ./configure --prefix=/usr \
        --disable-static \
        --with-glib \
        --enable-introspection=yes \
        --disable-gegl \
        --disable-docs \
        --disable-gperftools
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
