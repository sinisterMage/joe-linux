build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D docs=false \
        -D nls=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
