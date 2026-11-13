build() {
    mkdir -p build
    cd build
    # The documentation needs doxygen, graphviz and xmlto, none of which is part
    # of joe Linux. The test programs are not built because they are not run.
    # dtd_validation (the default) lets wayland-scanner check protocol files
    # against the DTD, with libxml2.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D documentation=false \
        -D dtd_validation=true \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
