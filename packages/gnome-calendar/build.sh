# Not in the book: the newest upstream release (GNOME 51), built with its
# meson files (the README gives no build instructions).
prepare() {
    patch -Np1 -i /recipe/libical-4.patch
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D profile=default \
        -D tracing=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
