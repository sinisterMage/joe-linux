# Not in the book: the newest upstream release, built as build_dist.sh
# builds release binaries (with its version stamps), without cgo.
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    export CGO_ENABLED=0

    # build_dist.sh gets these from git (cmd/mkversion), which the archive
    # lacks: the short version, and the long one with the first nine digits
    # of the commit tagged v1.104.7. The commit itself is stamped too, as
    # the Go tool would from a checkout.
    local commit=cbc74fe48ef1b1649f69a4d9a602319427e25102
    local ldflags="-X tailscale.com/version.longStamp=$PKG_VERSION-t${commit:0:9}"
    ldflags+=" -X tailscale.com/version.shortStamp=$PKG_VERSION"
    ldflags+=" -X tailscale.com/version.gitCommitStamp=$commit"
    grep -qx "$PKG_VERSION" VERSION.txt

    go build -ldflags "$ldflags" -o tailscale ./cmd/tailscale
    go build -ldflags "$ldflags" -o tailscaled ./cmd/tailscaled
}

package() {
    # Where upstream's packages put them, and where its units look.
    install -Dm755 tailscale "$DESTDIR/usr/bin/tailscale"
    install -Dm755 tailscaled "$DESTDIR/usr/sbin/tailscaled"

    # Upstream's units and their settings file. None is enabled;
    # tailscaled keeps its state in /var/lib/tailscale (StateDirectory).
    install -Dm644 cmd/tailscaled/tailscaled.defaults "$DESTDIR/etc/default/tailscaled"
    install -d "$DESTDIR/usr/lib/systemd/system"
    install -m644 cmd/tailscaled/tailscaled.service \
        cmd/tailscaled/tailscale-wait-online.service \
        cmd/tailscaled/tailscale-online.target \
        "$DESTDIR/usr/lib/systemd/system/"

    # Completions, as the program generates them.
    install -d "$DESTDIR/usr/share/bash-completion/completions" \
        "$DESTDIR/usr/share/zsh/site-functions" \
        "$DESTDIR/usr/share/fish/vendor_completions.d"
    ./tailscale completion bash > "$DESTDIR/usr/share/bash-completion/completions/tailscale"
    ./tailscale completion zsh > "$DESTDIR/usr/share/zsh/site-functions/_tailscale"
    ./tailscale completion fish > "$DESTDIR/usr/share/fish/vendor_completions.d/tailscale.fish"
}
