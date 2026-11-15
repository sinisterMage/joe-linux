build() {
    mkdir build
    cd build
    # The project has no options. colord (colour profiles) and libwebp
    # (WebP output) are found and used; PackageKit (offering to install
    # scanner drivers) has no recipe and is not found.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
