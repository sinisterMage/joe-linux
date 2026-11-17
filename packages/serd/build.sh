# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says. serdi and its manual page are installed. The reference
# documentation needs doxygen, sphinx and sphinxygen (which meson would try
# to fetch), and the HTML manual pages need mandoc, so neither is built.
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
        -D man_html=disabled \
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
