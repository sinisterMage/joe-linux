# Not in the book: the newest upstream release, built with meson as its
# README says.
build() {
    mkdir build
    cd build
    # Video streaming through GStreamer needs orc, which is not packaged;
    # nor is libcacard for smartcard pass-through. Clients may
    # authenticate through Cyrus SASL. The manual needs asciidoc. The tests
    # and the reds_stat tool are not installed.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gstreamer=no \
        -D lz4=true \
        -D opus=enabled \
        -D sasl=true \
        -D smartcard=disabled \
        -D manual=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
