build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=true \
        -D enable_vala=true \
        -D gtk_doc=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
