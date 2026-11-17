# Not in the book: the newest upstream release, built with meson as its
# README says, with every image format switched on explicitly.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D developer-mode=false \
        -D flatpak-build=false \
        -D colord=true \
        -D libwebp=true \
        -D librsvg=true \
        -D libheif=true \
        -D libjxl=true \
        -D libtiff=true \
        -D libgif=true \
        -D libraw=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
