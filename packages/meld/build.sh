# Not in the book: the newest upstream release, built with meson as its
# README says. The modules go into Python's site-packages.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D is_wheel=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
