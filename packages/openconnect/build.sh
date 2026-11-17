# Not in the book: the newest upstream release, built as its web page
# (www/building.xml) says.
build() {
    # GnuTLS is upstream's preferred TLS library. Left out because joe
    # does not package what they need: libproxy, RSA SecurID soft tokens
    # (stoken), PSKC token files (libpskc), and TPM keys (Trousers, tpm2-tss).
    # JSON (for the OIDC and some GlobalProtect logins) uses the parser
    # built in.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/libexec \
        --disable-static \
        --with-vpnc-script=/usr/share/vpnc-scripts/vpnc-script \
        --with-external-browser=/usr/bin/xdg-open \
        --with-gnutls \
        --with-gssapi \
        --with-libpcsclite \
        --with-lz4 \
        --with-builtin-json \
        --without-libproxy \
        --without-stoken \
        --without-libpskc \
        --without-gnutls-tss2 \
        --without-java
    make
}

package() {
    # Installs the library, the program, its bash completion, and the
    # host-scanning wrappers ("trojans") in /usr/libexec/openconnect for
    # gateways that demand them; those also need tools joe does not
    # package (xmlstarlet, Python's mechanize) and are run only when
    # asked for with --csd-wrapper.
    make DESTDIR="$DESTDIR" install
}
