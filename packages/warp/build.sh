# Not in the book: the newest upstream release, built with meson as its
# README describes. Upstream publishes no release tarball, only the git
# tag, and no checksum.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_options = \[/&'--locked', /" src/meson.build
    grep -q "'--locked'" src/meson.build
}

build() {
    mkdir build
    cd build
    # qr-code-scanning (upstream's default where GStreamer is found),
    # stated so that it does not depend on the build root.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default \
        -D qr-code-scanning=enabled
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
