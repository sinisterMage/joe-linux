build() {
    # Of the "Xorg Libraries" the book requires, configure looks for libX11
    # and libXau (authorisation of the libgtop server).
    ./configure --prefix=/usr \
        --disable-static \
        --with-x \
        --enable-introspection=yes \
        --disable-gtk-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
