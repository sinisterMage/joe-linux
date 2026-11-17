# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # SCTP tests need lksctp-tools' netinet/sctp.h, which joe does not
    # package, so SCTP is switched off rather than left to detection.
    ./configure --prefix=/usr \
        --disable-static \
        --with-openssl=/usr \
        --without-sctp
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # Upstream's unit for "iperf3 -s" (a dynamic user, sandboxed); not
    # enabled.
    install -Dm644 contrib/iperf3.service "$DESTDIR/usr/lib/systemd/system/iperf3.service"
}
