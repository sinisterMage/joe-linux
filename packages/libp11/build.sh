# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # With OpenSSL 4 only the provider is built (pkcs11prov.so, in
    # OpenSSL's modules directory); OpenSSL 4 has no engines. Tokens are
    # reached through p11-kit's proxy unless a program names a module.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-api-doc \
        --with-modulesdir=/usr/lib/ossl-modules \
        --with-pkcs11-module=/usr/lib/p11-kit-proxy.so
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
