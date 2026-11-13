build() {
    mkdir build
    cd build
    # The book's options, plus: no tests and no hotdoc documentation, and
    # --wrap-mode=nofallback so that the system's ffmpeg is the only one
    # that can be used.
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D tests=disabled \
        -D doc=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
