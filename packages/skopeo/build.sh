# Not in the book: the newest upstream release, built with its Makefile as
# its install.md describes, from the vendored modules. The build tags are
# the ones the Makefile would detect here, given explicitly: libsubid and
# libsqlite3, with btrfs left in. The signature code uses GPGME,
# upstream's default.
TAGS="libsubid libsqlite3"

go_env() {
    # Go's caches in the build directory, outside the source tree; never
    # fetch another Go toolchain. The Makefile adds -buildmode=pie itself.
    export GOPATH=/build/go
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -trimpath"
}

build() {
    go_env
    make PREFIX=/usr BUILDTAGS="$TAGS" bin/skopeo docs completions
}

package() {
    go_env
    # Not "make install": that also installs policy.json and
    # registries.d/default.yaml, which containers-common provides.
    make PREFIX=/usr BUILDTAGS="$TAGS" DESTDIR="$DESTDIR" \
        install-binary install-docs install-completions
}
