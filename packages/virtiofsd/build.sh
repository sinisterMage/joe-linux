# Not in the book: the newest upstream release, built with cargo as its
# README describes.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked
}

package() {
    # Where upstream's descriptor (50-virtiofsd.json) says the daemon is;
    # libvirt finds it through that descriptor in QEMU's vhost-user
    # directory.
    install -Dm755 target/release/virtiofsd "$DESTDIR/usr/libexec/virtiofsd"
    install -Dm644 50-virtiofsd.json "$DESTDIR/usr/share/qemu/vhost-user/50-virtiofsd.json"
}
