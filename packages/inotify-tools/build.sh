# Not in the book: the newest upstream release, built as its INSTALL says.
# Since 4.26 inotify-tools is written in Rust; its Makefile runs cargo and
# installs the programs and a libinotifytools.so that keeps the C library's
# soname and headers. Upstream releases every commit on master that passes
# its tests, numbered by the commit count.
prepare() {
    # The libc crate, as a vendored source in place of crates.io. Only the
    # package checksum is listed: cargo compares it with Cargo.lock.
    mkdir -p vendor/libc .cargo
    tar -xzf "$SOURCES/libc-0.2.183.crate" -C vendor/libc --strip-components=1
    printf '{"files":{},"package":"%s"}\n' \
        b5b646652bf6661599e1da8901b3b9522896f01e736bad5f723fe7a3a27f899d \
        > vendor/libc/.cargo-checksum.json
    cat > .cargo/config.toml << "EOT"
[source.crates-io]
replace-with = "vendored"

[source.vendored]
directory = "vendor"
EOT
}

build() {
    export CARGO_HOME="$PWD/.cargo-home"
    make prefix=/usr CARGOFLAGS="--locked --offline" ENABLE_STATIC=0
}

package() {
    export CARGO_HOME="$PWD/.cargo-home"
    make prefix=/usr libdir=/usr/lib CARGOFLAGS="--locked --offline" ENABLE_STATIC=0 \
        DESTDIR="$DESTDIR" install
}
