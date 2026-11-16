# Not in the book: the newest upstream release (0.39.0, 2012), built as its
# INSTALL says. atool reads /etc/atool.conf, which is not shipped (the
# defaults are compiled in).
build() {
    ./configure --prefix=/usr --sysconfdir=/etc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
