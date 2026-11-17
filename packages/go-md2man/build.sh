# Not in the book: the newest upstream release, built as its Makefile
# builds it (without cgo).
build() {
    # Keep Go's module and build caches inside the build directory, out of
    # the shared build root's /root; never fetch another Go toolchain.
    export GOPATH="$PWD/.gopath"
    export GOMODCACHE="$PWD/.gopath/pkg/mod"
    export GOCACHE="$PWD/.gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    export CGO_ENABLED=0
    go build -ldflags "-s -w" -o go-md2man .

    # Its own manual page, written in Markdown.
    ./go-md2man -in go-md2man.1.md -out go-md2man.1
}

package() {
    install -Dm755 go-md2man "$DESTDIR/usr/bin/go-md2man"
    install -Dm644 go-md2man.1 "$DESTDIR/usr/share/man/man1/go-md2man.1"
}
