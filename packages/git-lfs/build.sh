# Not in the book: the newest upstream release, built with upstream's
# Makefile as its RPM spec does (FORCE_LOCALIZE=true make). The manual
# pages need asciidoctor and are not built; "git lfs help" still works, as
# the Makefile builds the pages' text into the program.
build() {
    # Keep Go's module and build caches in the build directory, out of the
    # shared build root's /root, but beside the source tree rather than in
    # it: the Makefile runs gofmt over every .go file under the source tree.
    # Never fetch another Go toolchain.
    export GOPATH="${PWD%/*}/gopath"
    export GOMODCACHE="$GOPATH/pkg/mod"
    export GOCACHE="${PWD%/*}/gocache"
    export GOTOOLCHAIN=local GOTELEMETRY=off
    export GOFLAGS="-mod=readonly -modcacherw -trimpath -buildmode=pie"
    # The Makefile takes the commit it stamps into the program (git lfs
    # version) from git, and there is no repository here: this is the
    # commit the v3.8.1 tag points to. FORCE_LOCALIZE: msgfmt must
    # succeed, rather than the translations being skipped silently.
    make bin/git-lfs \
        GIT_LFS_SHA=a662a6dbfedf706cfa9fc7a5b7bcc7ba2e2c8a65 \
        VERSION=v3.8.1 \
        FORCE_LOCALIZE=true
}

package() {
    install -Dm755 bin/git-lfs "$DESTDIR/usr/bin/git-lfs"
}
