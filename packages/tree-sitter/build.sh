# Not in the book: the newest upstream release. The C library, built with
# upstream's Makefile; the command-line program (Rust) is tree-sitter-cli,
# from the same archive.
build() {
    # Without the Wasm feature, which needs wasmtime (no recipe).
    make PREFIX=/usr LIBDIR=/usr/lib
}

package() {
    make PREFIX=/usr LIBDIR=/usr/lib DESTDIR="$DESTDIR" install
    # The install target always copies the static library too.
    rm "$DESTDIR/usr/lib/libtree-sitter.a"
}
