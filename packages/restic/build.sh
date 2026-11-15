# Not in the book: the newest upstream release, built as its build.go and
# release helper (helpers/build-release-binaries) build it, without cgo.
# The version is a constant in internal/global, so no -X stamp is needed.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    # Upstream's build tags without "selfupdate": the package manager, not
    # "restic self-update", replaces this binary.
    go build -tags disable_grpc_modules -ldflags "-s -w" -o restic ./cmd/restic
}

package() {
    install -Dm755 restic "$DESTDIR/usr/bin/restic"
    # The manual pages and completions upstream generated for the release
    # (restic generate) and ships in doc/.
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 doc/man/*.1 "$DESTDIR/usr/share/man/man1/"
    install -Dm644 doc/bash-completion.sh "$DESTDIR/usr/share/bash-completion/completions/restic"
    install -Dm644 doc/zsh-completion.zsh "$DESTDIR/usr/share/zsh/site-functions/_restic"
    install -Dm644 doc/fish-completion.fish "$DESTDIR/usr/share/fish/vendor_completions.d/restic.fish"
}
