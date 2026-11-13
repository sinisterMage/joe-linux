build() {
    mkdir build
    cd build
    # No manual pages or HTML documentation: they need xmlto.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D man=false \
        -D docbook=false \
        -D mimeapps=true \
        -D systemduserunitdir=/usr/lib/systemd/user
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
