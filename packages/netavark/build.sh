# Not in the book: the newest upstream release, built with its Makefile
# offline from the crates upstream vendors for the release, as its
# DISTRO_PACKAGE.md describes.
prepare() {
    tar -xf "$SOURCES/netavark-v2.1.0-vendor.tar.gz"
    # .cargo/config.toml already holds upstream's test runner.
    cat >> .cargo/config.toml << "EOF2"

[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF2
}

build() {
    export CARGO_HOME="$PWD/.cargo-home"
    export PROTOC=/usr/bin/protoc
    make PREFIX=/usr CARGO="cargo --locked --offline" build docs
}

package() {
    # The binary goes in /usr/libexec/podman, where Podman looks for it;
    # the units (DHCP proxy, rules restored after a firewalld or nftables
    # reload) are not enabled.
    make PREFIX=/usr DESTDIR="$DESTDIR" install
}
