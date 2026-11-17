# Not in the book: the newest upstream release, built as its INSTALL.md
# says (make release, then install.sh), offline from the crates upstream
# vendors for the release.
prepare() {
    tar --zstd -xf "$SOURCES/libpathrs-0.2.6.vendor.tar.zst"
    mkdir -p .cargo
    cat > .cargo/config.toml << "EOF2"
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF2
}

build() {
    export CARGO_HOME="$PWD/.cargo-home"
    # Serially: hack/with-crate-type.sh sets the crate type by editing
    # Cargo.toml for the length of one cargo run, so the static and shared
    # library builds must not run at the same time.
    make -j1 release EXTRA_CARGO_FLAGS="--locked --offline"
}

package() {
    # install.sh reads DESTDIR from the environment. Only the shared
    # library is shipped.
    ./install.sh --prefix=/usr --libdir=/usr/lib --disable-static
}
