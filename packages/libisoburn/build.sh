build() {
    # As the book does. Not available: libedit (readline is used instead),
    # libjte and libcdio. ldconfig at install time would act on the build
    # root.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-pkg-check-modules \
        --enable-libreadline \
        --disable-libedit \
        --enable-libacl \
        --enable-xattr \
        --enable-zlib \
        --disable-libjte \
        --disable-libcdio \
        --disable-ldconfig-at-install
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # xorriso-tcltk is a graphical front end written for Tk's wish, which
    # joe Linux does not have.
    rm -v "$DESTDIR/usr/bin/xorriso-tcltk" "$DESTDIR/usr/share/man/man1/xorriso-tcltk.1"
}
