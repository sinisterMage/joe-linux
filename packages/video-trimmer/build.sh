# Not in the book: the newest upstream release, built with meson as its
# README describes. The release tarball is upstream's "meson dist" with
# the crates vendored (vendor/, .cargo/config); cargo finds that
# configuration from the build directory.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. The script
    # meson runs cargo with does not pass it.
    sed -i 's/Cargo.toml --release/& --locked/' build-aux/cargo.sh
    grep -q -- '--release --locked' build-aux/cargo.sh
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
