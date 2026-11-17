# Not in the book: newest stable upstream release, following INSTALL.
# Debian's source-only repack omits generated Autotools output.
prepare() {
    autoreconf -fiv
}

build() {
    RSVG=rsvg-convert INKSCAPE=false CONVERT=false \
        ./configure --prefix=/usr --libdir=/usr/lib --disable-static \
        --with-jpeg --with-tiff --enable-xmltools --enable-desktopfiles
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
