build() {
    mkdir -p build
    cd build
    # Data only. xsltproc (libxslt) generates the xkeyboard-config(7) manual page.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
