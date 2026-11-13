build() {
    mkdir -p build
    cd build
    # Headers and pkg-config files only; nothing is compiled.
    meson setup --prefix=/usr --libdir=lib ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
