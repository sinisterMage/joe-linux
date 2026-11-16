# Not in the book: the newest upstream release, built as its
# .goreleaser.yml builds it (cgo off, the version stamped with -X). The
# installation note keeps its default, "installed by building from
# source". The manual page is written in ronn, which has no recipe, so it
# is not built.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    go build -ldflags "-s -w -X github.com/rhysd/actionlint.version=$PKG_VERSION" \
        -o actionlint-bin ./cmd/actionlint
}

package() {
    install -Dm755 actionlint-bin "$DESTDIR/usr/bin/actionlint"
}
