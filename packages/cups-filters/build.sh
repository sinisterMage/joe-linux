prepare() {
    sed -i '/proc_func)()/s/()/(FILE*, FILE*, void*)/' filter/foomatic-rip/process.h
    patch -Np1 -i "$SOURCES/cups-filters-2.0.1-security_fix-1.patch"
}

build() {
    # The book's options, plus: sysconfdir, where foomatic-rip looks for
    # its configuration (it would be /usr/etc/foomatic); Ghostscript is
    # required, mutool (MuPDF) has no recipe.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir=/usr/share/doc/cups-filters-2.0.1 \
        --enable-ghostscript \
        --enable-poppler \
        --disable-mutool \
        --enable-driverless \
        --enable-foomatic
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
