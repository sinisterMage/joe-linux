build() {
    mkdir build
    cd build
    # The project has no options. --libdir is stated for consistency only:
    # the helper itself goes to /usr/libexec.
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
