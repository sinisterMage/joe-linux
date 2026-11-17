build() {
    mkdir build
    cd build
    # Every plugin with an outside dependency is named. Not built:
    # cdparanoia, libvisual and tremor (no such libraries), Orc
    # (not in the book), the Qt and GTK examples. The GL library takes its
    # APIs, platforms and window systems (X11, Wayland, GBM) from what mesa
    # provides.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D introspection=enabled \
        -D nls=enabled \
        -D tools=enabled \
        -D iso-codes=enabled \
        -D alsa=enabled \
        -D ogg=enabled \
        -D vorbis=enabled \
        -D opus=enabled \
        -D pango=enabled \
        -D drm=enabled \
        -D gl=enabled \
        -D gl-graphene=enabled \
        -D gl-jpeg=enabled \
        -D gl-png=enabled \
        -D x11=enabled \
        -D xshm=enabled \
        -D xvideo=enabled \
        -D xi=enabled \
        -D cdparanoia=disabled \
        -D libvisual=disabled \
        -D theora=enabled \
        -D tremor=disabled \
        -D orc=disabled \
        -D qt5=disabled \
        -D examples=disabled \
        -D tests=disabled \
        -D doc=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
