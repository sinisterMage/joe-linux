build() {
    mkdir build
    cd build
    # libglnx and gvdb are bundled in the tarball as subprojects, hence
    # nodownload rather than nofallback.
    # - flatpak-interfaces: Flatpak does not exist here.
    # - geoclue: the location portal; gudev: the USB portal.
    # - documentation: needs sphinx. tests: need umockdev, pytest, dbusmock.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D flatpak-interfaces=disabled \
        -D geoclue=enabled \
        -D gudev=enabled \
        -D systemd=enabled \
        -D sandboxed-image-validation=enabled \
        -D sandboxed-sound-validation=enabled \
        -D man-pages=enabled \
        -D documentation=disabled \
        -D tests=disabled \
        -D installed-tests=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
