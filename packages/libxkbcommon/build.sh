prepare() {
    # tools/info.c fails to build without this fix from upstream.
    patch -Np1 -i "$SOURCES/libxkbcommon-1.13.2-upstream_fix-1.patch"
}

build() {
    mkdir -p build
    cd build
    # enable-x11 builds libxkbcommon-x11 (needs libxcb's xcb-xkb), enable-wayland
    # the "xkbcli interactive-wayland" tool, enable-xkbregistry libxkbregistry
    # (needs libxml2). All three are the defaults; naming them turns a missing
    # dependency into an error. The location of the keyboard database is read
    # from xkeyboard-config's pkg-config file. No doxygen: no documentation.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D enable-docs=false \
        -D enable-x11=true \
        -D enable-wayland=true \
        -D enable-xkbregistry=true
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
