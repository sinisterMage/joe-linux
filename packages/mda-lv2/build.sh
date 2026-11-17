# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says. The bundle goes to /usr/lib/lv2/mda.lv2.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D dev=false \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
