# Not in the book: the newest upstream release, built with its Makefile as
# its README says, with upstream's default build tags (seccomp,
# urfave_cli_no_docs, libpathrs) and cgo, from the vendored modules.
go_env() {
    # Go's caches in the build directory, outside the source tree and out
    # of the shared build root's /root; never fetch another Go toolchain.
    export GOPATH=/build/go
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor"
}

build() {
    go_env
    # The Makefile adds -trimpath and -buildmode=pie itself. COMMIT would
    # be taken from git describe; the version comes from VERSION.
    make COMMIT= runc
    make man
}

package() {
    go_env
    # In /usr/bin rather than upstream's /usr/sbin, as other distributions
    # do; containerd, Podman and Docker find it on the PATH.
    make PREFIX=/usr BINDIR=/usr/bin DESTDIR="$DESTDIR" install install-man install-bash
}
