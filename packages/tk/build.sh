# Following the book's Tk page.
build() {
    cd unix
    # Xft (anti-aliased fonts) and XScreenSaver are on by default; said
    # explicitly so that a missing library fails the build instead of
    # silently changing it.
    ./configure --prefix=/usr \
        --mandir=/usr/share/man \
        --enable-64bit \
        --enable-xft \
        --enable-xss
    make

    # The configuration script extensions read would otherwise point into
    # this build tree.
    sed -e "s@^\(TK_SRC_DIR='\).*@\1/usr/include'@" \
        -e "/TK_B/s@='\(-L\)\?.*unix@='\1/usr/lib@" \
        -i tkConfig.sh
}

package() {
    cd unix
    # libtkstub8.6.a is static by design, like Tcl's stub library:
    # extensions link it to stay independent of the exact Tk version.
    make DESTDIR="$DESTDIR" install
    make DESTDIR="$DESTDIR" install-private-headers
    ln -v -sf wish8.6 "$DESTDIR/usr/bin/wish"
    chmod -v 755 "$DESTDIR/usr/lib/libtk8.6.so"
}
