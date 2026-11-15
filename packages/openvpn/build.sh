# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # OpenSSL; LZO and LZ4 for peers that still compress; data channel
    # offload (DCO) through libnl; the auth-pam and down-root plugins;
    # systemd notification and upstream's units. No PKCS#11 tokens
    # (pkcs11-helper is not packaged) and no SELinux. The manual pages ship
    # ready-made.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-crypto-library=openssl \
        --enable-lzo \
        --enable-lz4 \
        --enable-dco \
        --enable-plugins \
        --enable-plugin-auth-pam \
        --enable-plugin-down-root \
        --enable-management \
        --enable-systemd \
        --disable-pkcs11 \
        --disable-selinux
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # openvpn-client@NAME and openvpn-server@NAME read NAME.conf from these
    # directories. Neither unit is enabled.
    install -dm755 "$DESTDIR/etc/openvpn/client" "$DESTDIR/etc/openvpn/server"
    test -f "$DESTDIR/usr/lib/systemd/system/openvpn-client@.service"
    test -f "$DESTDIR/usr/lib/tmpfiles.d/openvpn.conf"
}
