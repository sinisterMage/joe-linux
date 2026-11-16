# Not in the book: the newest upstream release, built as its Makefile
# builds it (go build of cmd/mlr), without cgo. The version is a constant
# in pkg/version, so no -X stamp is needed.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    go build -o mlr ./cmd/mlr
}

package() {
    install -Dm755 mlr "$DESTDIR/usr/bin/mlr"
    # The manual page upstream generates (man/mkman.rb) and ships, as its
    # man/Makefile installs it.
    install -Dm644 man/mlr.1 "$DESTDIR/usr/share/man/man1/mlr.1"
}
