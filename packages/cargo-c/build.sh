prepare() {
    cp "$SOURCES/cargo-c-0.10.26-Cargo.lock" Cargo.lock
}

build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Use the system SQLite. LIBSSH2_SYS_USE_PKG_CONFIG is left unset:
    # libssh2 has no recipe, so the copy bundled with the libssh2-sys crate
    # is built in.
    export LIBSQLITE3_SYS_USE_PKG_CONFIG=1
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -d "$DESTDIR/usr/bin"
    install -m755 target/release/cargo-{capi,cbuild,cinstall,ctest} "$DESTDIR/usr/bin/"
}
