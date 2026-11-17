# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says. sordi, sord_validate (which needs PCRE2) and their manual
# pages are installed; the reference documentation (doxygen) is not built.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D tools=enabled \
        -D man=enabled \
        -D docs=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
