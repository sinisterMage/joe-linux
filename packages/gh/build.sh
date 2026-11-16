# Not in the book: the newest upstream release, built as its
# .goreleaser.yml builds the Linux binary (cgo off; version and the
# release's date, 2026-11-12, stamped with -X), with the manual pages and
# completions its Makefile's manpages and completions targets make.
#
# Left out: upstream's pre-build hook (script/licenses) installs
# go-licenses, a tool outside gh's go.mod, to embed third-party license
# texts; without it "gh licenses" says they are only in official builds.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    local date=2026-11-12
    local pkg=github.com/cli/cli/v2/internal/build
    go build -ldflags "-s -w -X $pkg.Version=$PKG_VERSION -X $pkg.Date=$date" \
        -o bin/gh ./cmd/gh

    # The manual pages, as "make manpages GH_VERSION=..." generates them,
    # dated like the release.
    GH_VERSION="$PKG_VERSION" SOURCE_DATE_EPOCH="$(date -u -d "$date" +%s)" \
        go run ./cmd/gen-docs --man-page --doc-path ./share/man/man1/

    # Shell completions, as "make completions" generates them, with a
    # scratch home so gh's configuration lookup stays out of the build
    # root's /root.
    local shell
    for shell in bash zsh fish; do
        HOME="$PWD/.home" XDG_CONFIG_HOME="$PWD/.home/.config" \
            bin/gh completion -s "$shell" > "gh.$shell"
    done
}

package() {
    install -Dm755 bin/gh "$DESTDIR/usr/bin/gh"
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 share/man/man1/*.1 "$DESTDIR/usr/share/man/man1/"
    install -Dm644 gh.bash "$DESTDIR/usr/share/bash-completion/completions/gh"
    install -Dm644 gh.zsh "$DESTDIR/usr/share/zsh/site-functions/_gh"
    install -Dm644 gh.fish "$DESTDIR/usr/share/fish/vendor_completions.d/gh.fish"
}
