build() {
    mkdir build
    cd build
    meson setup --prefix=/usr --buildtype=release -D libdir=lib ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
