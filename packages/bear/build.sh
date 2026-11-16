# Not in the book: the newest upstream release, built with cargo as its
# INSTALL.md says. Since 4.0 Bear is written in Rust (with a small C shim in
# the preload library) and no longer needs gRPC, protobuf or spdlog.
# Upstream publishes no checksum for the source archive.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
    target/release/generate-completions target/release/completions
}

package() {
    # bear (a shell script) in /usr/bin; bear-driver, bear-wrapper and the
    # preload library libexec.so under /usr/libexec/bear; the manual page
    # and the bash, zsh, fish and elvish completions.
    DESTDIR="$DESTDIR" PREFIX=/usr LIBEXECDIR=/usr/libexec sh scripts/install.sh
}
