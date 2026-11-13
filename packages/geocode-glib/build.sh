build() {
    mkdir build
    cd build
    # Built against libsoup 3 only (geocode-glib-2.0).
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D soup2=false \
        -D enable-introspection=true \
        -D enable-gtk-doc=false \
        -D enable-installed-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
