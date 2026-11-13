build() {
    mkdir build
    cd build
    # No libproxy in joe Linux.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gnutls=enabled \
        -D openssl=disabled \
        -D libproxy=disabled \
        -D gnome_proxy=enabled \
        -D tests=false \
        -D installed_tests=false
    ninja
}

package() {
    cd build
    # With DESTDIR set meson does not run gio-querymodules for the modules
    # in usr/lib/gio/modules; glib's trigger does.
    DESTDIR="$DESTDIR" ninja install
}
