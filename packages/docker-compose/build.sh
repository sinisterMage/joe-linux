# Not in the book: the newest upstream release, built as its Makefile's
# build target and release Dockerfile build it (no cgo, the e2e tag,
# the version stamped in). The Makefile itself is not used: it writes the
# binary to $DESTDIR when that is set, and the build driver sets it.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    go build -tags e2e \
        -ldflags "-s -w -X github.com/docker/compose/v5/internal.Version=v$PKG_VERSION" \
        -o docker-compose ./cmd
}

package() {
    # A docker CLI plugin, found by "docker compose" in this directory.
    install -Dm755 docker-compose "$DESTDIR/usr/lib/docker/cli-plugins/docker-compose"
}
