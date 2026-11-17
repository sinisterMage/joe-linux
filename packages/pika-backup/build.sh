# Not in the book: the newest upstream release, built with meson as its
# README describes. Upstream publishes no release tarball, only the git
# tag, and no checksum.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_options = \[/&'--locked', /" pika-backup/src/meson.build
    grep -q "'--locked'" pika-backup/src/meson.build

    # The openssl and openssl-sys crates in upstream's Cargo.lock (0.10.76,
    # 0.9.112) refuse OpenSSL 4. Move the lock file to the releases that
    # support it; nothing else in it changes.
    CARGO_HOME="$PWD/.cargo-home" cargo update -p openssl --precise 0.10.82
    [[ $(grep -A1 '^name = "openssl-sys"$' Cargo.lock) == *'"0.9.118"'* ]]
}

build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D profile=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
