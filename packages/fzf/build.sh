# Not in the book: the newest upstream release, built as its Makefile and
# .goreleaser.yml build it (cgo off, the version and revision stamped with
# -X; c7bf2b8e is the commit the v0.75.0 tag points to, abbreviated as the
# Makefile does).
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -trimpath -buildmode=pie -modcacherw"
    export CGO_ENABLED=0
    go build -ldflags "-s -w -X main.version=$PKG_VERSION -X main.revision=c7bf2b8e" -o fzf-bin .
}

package() {
    install -Dm755 fzf-bin "$DESTDIR/usr/bin/fzf"
    install -m755 bin/fzf-tmux bin/fzf-preview.sh "$DESTDIR/usr/bin/"
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 man/man1/fzf.1 man/man1/fzf-tmux.1 "$DESTDIR/usr/share/man/man1/"

    # The shell integration scripts (also printed by fzf --bash, --zsh and
    # --fish), for users to source. bash-completion loads completion.bash
    # when fzf is first completed (it registers fzf's option completion),
    # and fish's key bindings become an autoloaded function,
    # fzf_key_bindings. completion.zsh is no #compdef file, so it stays in
    # usr/share/fzf only.
    install -d "$DESTDIR/usr/share/fzf"
    install -m644 shell/key-bindings.{bash,zsh,fish} shell/completion.{bash,zsh,fish} \
        "$DESTDIR/usr/share/fzf/"
    install -Dm644 shell/completion.bash "$DESTDIR/usr/share/bash-completion/completions/fzf"
    install -Dm644 shell/key-bindings.fish "$DESTDIR/usr/share/fish/vendor_functions.d/fzf_key_bindings.fish"

    # The Vim plugin, in the system-wide plugin directory Vim loads.
    install -Dm644 plugin/fzf.vim "$DESTDIR/usr/share/vim/vimfiles/plugin/fzf.vim"
}
