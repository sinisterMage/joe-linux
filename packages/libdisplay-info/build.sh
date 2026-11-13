build() {
    mkdir -p build
    cd build
    # The PNP id table is compiled in from hwdata's pnp.ids at build time.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
