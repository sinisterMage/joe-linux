build() {
    mkdir build
    cd build
    # The book's options (selinux=disabled), plus:
    # - tests=none: the test suite needs localsearch.
    # - docs: gi-docgen does not exist here.
    # - extensions, introspection and cloudproviders as upstream's defaults,
    #   stated so that they do not depend on the build root.
    # --wrap-mode=nodownload: libgxdp is shipped in the tarball.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nodownload \
        -D selinux=disabled \
        -D cloudproviders=enabled \
        -D extensions=true \
        -D introspection=true \
        -D docs=false \
        -D tests=none
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
