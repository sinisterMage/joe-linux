prepare() {
    # The book: use the system's freetype, lcms2, libjpeg, libpng, openjpeg
    # and zlib instead of the copies in the tarball.
    rm -rf freetype lcms2mt jpeg libpng openjpeg
    rm -rf zlib
}

build() {
    # The book's options, plus:
    # - CUPS required (it is optional and found by cups-config otherwise);
    # - no display devices: no GTK loader (gsx) and no X11 output, since
    #   Ghostscript is here for printing and conversion;
    # - libidn and libpaper have no recipe.
    ./configure --prefix=/usr \
        --disable-compile-inits \
        --with-system-libtiff \
        --enable-cups \
        --enable-fontconfig \
        --enable-openjpeg \
        --enable-dbus \
        --disable-gtk \
        --without-x \
        --without-libidn \
        --without-libpaper \
        CFLAGS="${CFLAGS:--g -O3} -fPIC"
    make
    # libgs.so, which the book builds too.
    make so
}

package() {
    make DESTDIR="$DESTDIR" install
    make DESTDIR="$DESTDIR" soinstall
    install -v -m644 base/*.h "$DESTDIR/usr/include/ghostscript"
    ln -sfvn ghostscript "$DESTDIR/usr/include/ps"
}
