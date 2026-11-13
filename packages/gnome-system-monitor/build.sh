build() {
    mkdir build
    cd build
    # The book builds with the defaults, stated here.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --wrap-mode=nofallback \
        -D systemd=true \
        -D development=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
