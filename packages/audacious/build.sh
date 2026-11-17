# Following the book's Audacious page, with only the GTK 3 interface
# libraries: joe Linux is a GNOME desktop with all of GTK 3, while its Qt 6
# lacks Qt Multimedia, which the Qt build's audio output plugin needs. So
# -D qt=false here and in audacious-plugins. D-Bus control (audtool) and
# libarchive are on; valgrind support is off.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D gtk=true \
        -D gtk2=false \
        -D qt=false \
        -D qt5=false \
        -D dbus=true \
        -D libarchive=true \
        -D valgrind=false \
        -D buildstamp="joe Linux"
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
