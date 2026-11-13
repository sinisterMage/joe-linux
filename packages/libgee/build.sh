build() {
    # The book's options, plus introspection stated (g-ir-scanner is part of
    # glib here; gnome-calculator's GCalc typelib refers to Gee-0.8).
    ./configure --prefix=/usr \
        --disable-static \
        --enable-vala \
        --enable-introspection=yes
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
