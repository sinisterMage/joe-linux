# Not in the book: the newest upstream release. README.md builds with make;
# upstream's meson.build installs the same files and is used here.
build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --sysconfdir=/etc \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
