# Not in the book: the newest upstream release, built with meson as its
# README describes. The release tarball is upstream's "meson dist" with
# the crates vendored (vendor/, .cargo/config); cargo finds that
# configuration from the build directory.
prepare() {
    # --locked: build exactly the crate versions in Cargo.lock. Meson's
    # cargo invocation does not pass it.
    sed -i "s/^cargo_options = \[/&'--locked', /" src/meson.build
    grep -q "'--locked'" src/meson.build

    # The openssl and openssl-sys crates in upstream's Cargo.lock (0.10.71,
    # 0.9.106) refuse OpenSSL 4. Vendor the releases that support it beside
    # them and let cargo move the lock file to those two, offline; nothing
    # else in it changes. Only the package checksum is listed: cargo
    # compares it with Cargo.lock.
    local crate
    for crate in openssl-0.10.82 openssl-sys-0.9.118; do
        mkdir "vendor/$crate"
        tar -xzf "$SOURCES/$crate.crate" -C "vendor/$crate" --strip-components=1 --no-same-owner
    done
    printf '{"files":{},"package":"%s"}\n' \
        4de8111e94a56adca7ebfe6c365b6d42f99deb69b74b6becacd4204e2f193aa2 \
        > vendor/openssl-0.10.82/.cargo-checksum.json
    printf '{"files":{},"package":"%s"}\n' \
        19c413d6ec9ebaf5e1c829d355cb3e9f783778d700f135be0921d52fce3c60ae \
        > vendor/openssl-sys-0.9.118/.cargo-checksum.json
    CARGO_HOME="$PWD/.cargo-home" cargo update --offline -p openssl --precise 0.10.82
    [[ $(grep -A1 '^name = "openssl-sys"$' Cargo.lock) == *'"0.9.118"'* ]]
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
