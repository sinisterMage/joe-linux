# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says. The reference documentation needs doxygen, sphinx and
# sphinxygen (which meson would try to fetch), so it is not built.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D docs=disabled \
        -D html=disabled \
        -D singlehtml=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
