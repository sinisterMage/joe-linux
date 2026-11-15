build() {
    # The book's options, except that the PPD compiler utilities (ppdc,
    # ppdhtml, ppdi, ppdmerge, ppdpo) are left to CUPS 2.4, which installs
    # the same programs; libppd only needs them with CUPS 3. Plus:
    # Ghostscript and Poppler (pdftops,
    # pdftocairo) as the PostScript renderers, "hybrid" choosing between
    # them as upstream does by default; mutool (MuPDF) and acroread do not
    # exist here.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --with-cups-rundir=/run/cups \
        --disable-ppdc-utils \
        --docdir=/usr/share/doc/libppd-2.1.1 \
        --enable-ghostscript \
        --enable-pdftops \
        --enable-pdftocairo \
        --disable-mutool \
        --disable-acroread \
        --with-pdftops=hybrid
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
