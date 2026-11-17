# Following the book's Snapshot page. The release tarball vendors the
# crates (vendor/, .cargo/config.toml); cargo finds that configuration from
# the build directory.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_build_options = \[/&'--locked', /" meson.build
    grep -q "'--locked'" meson.build
}

build() {
    mkdir build
    cd build
    # The book's options, plus:
    # - x11: only adds X11 window handles for the portals; the desktop is
    #   Wayland only (as for loupe).
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default \
        -D x11=disabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
