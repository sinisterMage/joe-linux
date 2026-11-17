# Not in the book: the newest upstream release, built with its Makefile
# offline from the crates upstream vendors for the release, as its
# DISTRO_PACKAGE.md describes. Upstream has no manual page.
prepare() {
    tar -xf "$SOURCES/aardvark-dns-v2.1.0-vendor.tar.gz"
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
    make PREFIX=/usr CARGO="cargo --locked --offline" build
}

package() {
    # In /usr/libexec/podman, where netavark looks for it.
    make PREFIX=/usr DESTDIR="$DESTDIR" install
}
