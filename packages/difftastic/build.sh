# Not in the book: the newest upstream release, built with cargo as its
# manual's "Packaging Difftastic" page describes. Upstream publishes no
# checksum for the source archive. rust-toolchain.toml only matters to
# rustup and is ignored here.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # The tree-sitter grammars (those in vendored_parsers/ and those from
    # crates.io) are C sources compiled with cc and linked in; they have no
    # recipes of their own. jemalloc, difftastic's allocator, has none
    # either: tikv-jemalloc-sys builds the copy it carries (with make).
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/difft "$DESTDIR/usr/bin/difft"
    # The manual page upstream generates with pandoc and ships.
    install -Dm644 difft.1 "$DESTDIR/usr/share/man/man1/difft.1"
}
