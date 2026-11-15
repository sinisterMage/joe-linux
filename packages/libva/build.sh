build() {
    # The book configures in the tarball's own build directory.
    cd build
    # The library only: the drivers (intel-media-driver, Mesa's gallium VA
    # driver) and libva-utils are separate. Stated rather than detected:
    # the DRM, X11 and Wayland back ends are built; libva-glx is not, since
    # it would need Mesa's libGL while Mesa's VA driver needs this package.
    # The reference manual would need Doxygen.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D disable_drm=false \
        -D with_x11=yes \
        -D with_glx=no \
        -D with_wayland=yes \
        -D enable_docs=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
