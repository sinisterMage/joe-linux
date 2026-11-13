build() {
    mkdir build
    cd build
    # The Python override would need PyGObject at build time only to find
    # the directory to install one file in.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D introspection=true \
        -D vapi=true \
        -D tools=true \
        -D python3=false \
        -D gtk_doc=false \
        -D tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
