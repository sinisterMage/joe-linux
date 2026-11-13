build() {
    # Every optional library is stated so that the build root cannot change
    # the result. xar support uses expat rather than libxml2 (which would pull
    # ICU into cmake's dependencies); crypto comes from OpenSSL, the Nettle
    # code being broken with Nettle 4.
    ./configure --prefix=/usr \
        --disable-static \
        --with-zlib \
        --with-bz2lib \
        --with-lzma \
        --with-zstd \
        --with-lz4 \
        --with-openssl \
        --with-expat \
        --without-xml2 \
        --without-nettle \
        --without-mbedtls \
        --without-lzo2 \
        --without-libb2
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # bsdunzip stands in for the unmaintained Unzip package.
    ln -sfv bsdunzip "$DESTDIR/usr/bin/unzip"
}
