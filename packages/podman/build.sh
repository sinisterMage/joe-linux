# Not in the book: the newest upstream release, built with its Makefile as
# its install.md describes, from the vendored modules. The build tags are
# the ones the Makefile would detect here, given explicitly so that the
# result does not depend on what the build root holds: libsqlite3, systemd,
# libsubid and seccomp; btrfs is left in; apparmor is off (joe has no
# AppArmor). The signature code uses GPGME, upstream's default.
TAGS="grpcnotrace libsqlite3 systemd libsubid seccomp"

go_env() {
    # Go's caches in the build directory, outside the source tree (the
    # Makefile finds every .go file under it); never fetch another Go
    # toolchain.
    export GOPATH=/build/go
    export GOCACHE=/build/go/cache
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=vendor -trimpath -buildmode=pie"
    # The driver exports SOURCES=/sources. Make reuses that name for its
    # source-file list, which exceeds Linux's per-environment-string limit
    # when exported with the vendored modules.
    export -n SOURCES
}

build() {
    go_env
    make PREFIX=/usr BUILDTAGS="$TAGS" \
        podman podman-remote podmansh rootlessport quadlet
    # The manual pages, converted by the go-md2man vendored in test/tools.
    make PREFIX=/usr BUILDTAGS="$TAGS" docs
}

package() {
    go_env
    # Upstream's units (the API service and socket, auto-update, restart,
    # kube) for the system and for user sessions; none is enabled. The
    # quadlet generators are installed as upstream does. The shell
    # completions are pregenerated in the archive. install.docker (a docker
    # command that runs podman) is left out: there is a real docker.
    make PREFIX=/usr BUILDTAGS="$TAGS" DESTDIR="$DESTDIR" \
        install install.completions
}
