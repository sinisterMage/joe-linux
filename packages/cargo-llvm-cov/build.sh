# Not in the book: the newest upstream release, built with cargo as its
# README describes (cargo install cargo-llvm-cov --locked).
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/cargo-llvm-cov "$DESTDIR/usr/bin/cargo-llvm-cov"

    # Unless LLVM_COV and LLVM_PROFDATA are set, cargo-llvm-cov looks for the
    # tools where rustup's llvm-tools component puts them: beside rustc's
    # target libraries. joe's rustc is built against the system LLVM, whose
    # tools are the matching ones, so link them there.
    local dir=usr/lib/rustlib/x86_64-unknown-linux-gnu/bin tool
    install -d "$DESTDIR/$dir"
    for tool in llvm-cov llvm-profdata; do
        ln -s "/usr/bin/$tool" "$DESTDIR/$dir/$tool"
    done
}
