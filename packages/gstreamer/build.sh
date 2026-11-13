build() {
    mkdir build
    cd build
    # The PTP helper is written in Rust and wants capabilities or set-uid;
    # libunwind and libdw only serve stack traces in debug output, which
    # gst_debug=false removes anyway.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D gst_debug=false \
        -D introspection=enabled \
        -D nls=enabled \
        -D tools=enabled \
        -D check=enabled \
        -D ptp-helper=disabled \
        -D libunwind=disabled \
        -D libdw=disabled \
        -D dbghelp=disabled \
        -D bash-completion=disabled \
        -D examples=disabled \
        -D tests=disabled \
        -D benchmarks=disabled \
        -D doc=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
