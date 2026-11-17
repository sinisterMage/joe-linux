# Following the book's gnome-user-docs page.
build() {
    mkdir build
    cd build
    # tests=false: the tests need yelp-check (yelp-tools).
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
