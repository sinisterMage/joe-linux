prepare() {
    patch -Np1 -d deps/v8 -i "$SOURCES/node-v26.13.1-icu4c-79_fix-1.patch"
}

build() {
    ./configure --prefix=/usr \
        --shared-brotli \
        --shared-cares \
        --shared-libuv \
        --shared-nghttp2 \
        --shared-openssl \
        --shared-simdutf \
        --shared-zlib \
        --with-intl=system-icu
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
