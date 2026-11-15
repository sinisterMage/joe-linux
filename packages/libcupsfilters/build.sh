build() {
    # The book's options, plus what it leaves to the build root:
    # - mutool (MuPDF) has no recipe; Ghostscript and Poppler are the PDF
    #   renderers;
    # - libexif (reading the orientation of photos) has no recipe;
    # - JPEG XL, PNG, TIFF and JPEG images, Poppler, D-Bus (colord) and the
    #   texttopdf filter (fontconfig) are on.
    # localstatedir and sysconfdir as everywhere else; the CUPS paths come
    # from cups.pc.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir=/usr/share/doc/libcupsfilters-2.1.2 \
        --enable-ghostscript \
        --disable-mutool \
        --enable-poppler \
        --enable-dbus \
        --disable-exif \
        --with-jpeg \
        --with-png \
        --with-tiff \
        --with-jpegxl \
        --with-fontconfig \
        --enable-imagefilters \
        --enable-texttopdf \
        --with-cups-rundir=/run/cups
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
