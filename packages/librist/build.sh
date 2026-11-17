# Not in the book: the newest upstream release, built with meson as its
# README says. fallback_builtin=false makes meson fail rather than compile
# in the bundled copies of Mbed TLS, cJSON and LZ4 when the system's are
# missing. The tools (ristsender, ristreceiver, rist2rist, risttunnel,
# udp2udp, ristsrppasswd) are built; the tests are not. cmake is how meson
# finds Mbed TLS.
build() {
    meson setup build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D test=false \
        -D built_tools=true \
        -D use_mbedtls=true \
        -D use_gnutls=false \
        -D builtin_mbedtls=false \
        -D builtin_cjson=false \
        -D builtin_lz4=false \
        -D fallback_builtin=false \
        -D static_analyze=false
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
