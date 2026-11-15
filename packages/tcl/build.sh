build() {
    SRCDIR=$(pwd)
    cd unix
    ./configure --prefix=/usr \
        --mandir=/usr/share/man \
        --disable-rpath
    make

    # The configuration scripts extensions read would otherwise point into
    # this build tree.
    sed -e "s|$SRCDIR/unix|/usr/lib|" \
        -e "s|$SRCDIR|/usr/include|" \
        -i tclConfig.sh

    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.13|/usr/lib/tdbc1.1.13|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.13/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.13/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.13|/usr/include|" \
        -i pkgs/tdbc1.1.13/tdbcConfig.sh

    sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.7|/usr/lib/itcl4.3.7|" \
        -e "s|$SRCDIR/pkgs/itcl4.3.7/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/itcl4.3.7|/usr/include|" \
        -i pkgs/itcl4.3.7/itclConfig.sh
}

package() {
    cd unix
    # The stub libraries (libtclstub8.6.a and those of Itcl and TDBC) are
    # static by design: extensions link them to stay independent of the
    # exact Tcl version.
    make DESTDIR="$DESTDIR" install
    chmod 644 "$DESTDIR/usr/lib/libtclstub8.6.a"
    chmod -v u+w "$DESTDIR/usr/lib/libtcl8.6.so"

    # Expect is built against Tcl's private headers.
    make DESTDIR="$DESTDIR" install-private-headers

    ln -sfv tclsh8.6 "$DESTDIR/usr/bin/tclsh"

    # Perl has a Thread(3) manual page too.
    mv -v "$DESTDIR"/usr/share/man/man3/{Thread,Tcl_Thread}.3
}
