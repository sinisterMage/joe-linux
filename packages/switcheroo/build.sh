# Not in the book: the newest upstream release, built with meson as its
# README describes. The release tarball is upstream's "meson dist" with
# the crates vendored (vendor/, .cargo/config); cargo finds that
# configuration from the build directory. Upstream publishes no checksum
# for it.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_options = \[/&'--locked', /" src/meson.build
    grep -q "'--locked'" src/meson.build
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=default
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
