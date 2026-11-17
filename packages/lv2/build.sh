# Not in the book: the newest upstream release (1.18.10, still current),
# built with meson as its INSTALL.md says. The example plugins (eg-*.lv2)
# are left out: they are samples for plugin writers, and two of them need
# GTK 2. The documentation needs doxygen and lv2specgen's Python modules.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D docs=disabled \
        -D online_docs=false \
        -D plugins=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
