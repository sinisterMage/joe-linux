# Not in the book: the newest upstream release, built with Samba's waf as
# talloc is. Rhythmbox keeps its music library in a tdb file.
#
# Only the library, its header and its pkg-config file are packaged: joe's
# samba recipe builds its own private copy of tdb and ships the tdb tools
# (tdbtool, tdbdump, tdbbackup, tdbrestore), their manual pages and the
# Python tdb module from it, and two packages cannot own the same files.
# If samba is ever switched to this system tdb (--bundled-libraries without
# tdb), the tools and the Python module can move here.
build() {
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --disable-python
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    rm -rf "$DESTDIR/usr/bin" "$DESTDIR/usr/share/man"
}
