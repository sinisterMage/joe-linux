prepare() {
    # Fix some deprecated entries in the schema templates.
    sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D introspection=true
    ninja
}

package() {
    cd build
    # With DESTDIR set meson does not run glib-compile-schemas; glib's
    # trigger compiles the schemas on the installed system.
    DESTDIR="$DESTDIR" ninja install
}
