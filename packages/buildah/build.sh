# Not in the book: the newest upstream release, built with its Makefile as
# its install.md describes, from the vendored modules. The build tags are
# the ones the Makefile would detect here, given explicitly so that the
# result does not depend on what the build root holds: seccomp, libsubid,
# systemd and libsqlite3; btrfs is left in; apparmor is off (joe has no
# AppArmor). The signature code uses GPGME, upstream's default.
TAGS="seccomp libsubid systemd libsqlite3"

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
    make PREFIX=/usr BUILDTAGS="$TAGS" bin/buildah
    # The manual pages, converted by the go-md2man vendored in tests/tools.
    make PREFIX=/usr BUILDTAGS="$TAGS" docs
}

package() {
    go_env
    make PREFIX=/usr BUILDTAGS="$TAGS" DESTDIR="$DESTDIR" install install.completions
}
