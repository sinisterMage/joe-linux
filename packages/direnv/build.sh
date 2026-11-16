# Not in the book: the newest upstream release, built and installed as its
# GNUmakefile does (cgo off as in its dist target, BASH_PATH fixing the
# bash that evaluates .envrc files). The version is embedded from
# version.txt, so no -X stamp is needed.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    go build -ldflags "-s -w -X main.bashPath=/usr/bin/bash" -o direnv-bin
}

package() {
    install -Dm755 direnv-bin "$DESTDIR/usr/bin/direnv"
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 man/*.1 "$DESTDIR/usr/share/man/man1/"
    # As upstream's install target does: hook direnv into fish. bash and zsh
    # users add "eval "$(direnv hook bash)"" to their rc file themselves.
    install -d "$DESTDIR/usr/share/fish/vendor_conf.d"
    echo "/usr/bin/direnv hook fish | source" > "$DESTDIR/usr/share/fish/vendor_conf.d/direnv.fish"
}
