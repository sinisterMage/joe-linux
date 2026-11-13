build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D introspection=true \
        -D vapigen=true \
        -D enable-gtk-doc=false \
        -D installed-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
