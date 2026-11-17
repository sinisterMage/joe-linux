# Not in the book: the newest upstream release, built as the buildctl and
# buildkitd stages of its Dockerfile build them (no cgo, the same tags and
# version stamps), from the vendored modules. f55949de... is the commit
# v0.35.0 points to, which the Dockerfile takes from git.
build() {
    # Go's build cache inside the build directory, out of the shared build
    # root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    local pkg=github.com/moby/buildkit
    local ldflags="-s -w -X $pkg/version.Version=v$PKG_VERSION -X $pkg/version.Revision=f55949dea4f03bb9d85b73e9afc9a609291289db -X $pkg/version.Package=$pkg"
    go build -tags grpcnotrace -ldflags "$ldflags" -o buildctl ./cmd/buildctl
    go build -tags "osusergo netgo static_build seccomp grpcnotrace" \
        -ldflags "$ldflags" -o buildkitd ./cmd/buildkitd
}

package() {
    install -Dm755 buildctl "$DESTDIR/usr/bin/buildctl"
    install -Dm755 buildkitd "$DESTDIR/usr/bin/buildkitd"

    # Upstream's example system unit and socket (examples/systemd/system),
    # pointed at where buildkitd is installed. Neither is enabled. The
    # rootless user units are left out: they need RootlessKit.
    install -d "$DESTDIR/usr/lib/systemd/system"
    sed 's|/usr/local/bin/buildkitd|/usr/bin/buildkitd|' examples/systemd/system/buildkit.service \
        > "$DESTDIR/usr/lib/systemd/system/buildkit.service"
    install -m644 examples/systemd/system/buildkit.socket "$DESTDIR/usr/lib/systemd/system/"
}
