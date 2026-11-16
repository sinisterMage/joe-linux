# Not in the book: the newest upstream release, built as its release notes
# say the binaries are ("CGO_ENABLED=0 go build -trimpath -ldflags=-w -s").
# The manual page is written in scdoc, which has no recipe, so it is not
# built.
prepare() {
    # shfmt prints the main module's version from Go's build information,
    # which only a build inside upstream's git checkout (or "go install
    # ...@v3.14.1") fills in; built from the archive it would print
    # "(devel)". Print the release's tag instead, as upstream's binaries do.
    sed -i 's|version = mod.Version$|version = "v'"$PKG_VERSION"'"|' cmd/shfmt/main.go
    grep -q "version = \"v$PKG_VERSION\"" cmd/shfmt/main.go
}

build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    go build -ldflags "-w -s" -o shfmt-bin ./cmd/shfmt
}

package() {
    install -Dm755 shfmt-bin "$DESTDIR/usr/bin/shfmt"
}
