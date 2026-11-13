build() {
    # The font directory is otherwise asked from font-util's pkg-config file when
    # that happens to be installed; this is its value, and the default without it.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir="/usr/share/doc/libfontenc-$PKG_VERSION" \
        --with-fontrootdir=/usr/share/fonts/X11
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
