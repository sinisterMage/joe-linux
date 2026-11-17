# Following the book's ldns page, with the example programs built as well:
# they are the ldns-* utilities (ldns-keygen, ldns-signzone, ldns-dane,
# ldns-verify-zone, ldns-dpa with libpcap and so on), not samples.
build() {
    # drill and ldns-dane read the DNSSEC root trust anchor from where the
    # unbound package keeps it up to date, not /etc/unbound/root.key.
    # ldns-dane uses OpenSSL's default certificate paths. No Python (SWIG)
    # or Perl bindings.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-drill \
        --with-examples \
        --with-ssl=/usr \
        --with-trust-anchor=/var/lib/unbound/root.key \
        --without-pyldns \
        --without-pyldnsx \
        --without-p5-dns-ldns
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
