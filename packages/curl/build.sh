build() {
    # brotli is left out on purpose: brotli needs cmake to build and cmake
    # uses this curl, so enabling it here would be a dependency cycle.
    # The other switches after --with-ca-path state what the build root would
    # otherwise decide.
    ./configure --prefix=/usr \
        --disable-static \
        --with-openssl \
        --with-ca-path=/etc/ssl/certs \
        --with-zlib \
        --with-zstd \
        --with-libpsl \
        --with-nghttp2 \
        --with-libidn2 \
        --without-brotli \
        --without-libssh2 \
        --without-libssh \
        --without-libgsasl \
        --without-gssapi \
        --disable-ldap \
        --disable-ldaps \
        --disable-ares
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
