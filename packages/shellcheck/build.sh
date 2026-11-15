# Not in the book: the newest upstream release, built with cabal as its
# README ("Compiling from source") says, after the step upstream's own
# release builds (builders/*/build) and distributions take first:
# ./striptests deletes the unit tests from the sources, which drops
# ShellCheck's own use of QuickCheck and Template Haskell and makes the
# binary much smaller.
#
# cabal downloads the Hackage libraries ShellCheck needs. cabal.project pins
# the Hackage index to the day after the release (index-state), so every
# build resolves the same versions; the resolved plan is printed into the
# build log. The libraries are linked into the binary statically, as cabal
# does by default.
#
# No man page: upstream builds it from shellcheck.1.md with pandoc.

_shellcheck_env() {
    # cabal and GHC read and write UTF-8; the build sandbox's POSIX locale
    # makes them fail on the first non-ASCII character.
    export LANG=C.UTF-8 LC_ALL=C.UTF-8
    # cabal's configuration, Hackage index, downloads and package store
    # stay in the build directory, out of the shared build root.
    export HOME="$PWD/.home" CABAL_DIR="$PWD/.cabal"
}

prepare() {
    mkdir .home
    bash ./striptests

    # - index-state: the Hackage index as it was the day after ShellCheck
    #   0.11.0 was released (2025-08-04).
    # - http-transport: the HTTP client built into cabal (Hackage is served
    #   over plain HTTP and cabal checks the index's signatures), so the
    #   build does not depend on curl and the CA certificates.
    # - split-sections for every package, as upstream's release builds pass
    #   -split-sections: the linker can then drop the unused parts of the
    #   libraries.
    cat > cabal.project << "EOF"
packages: .
index-state: hackage.haskell.org 2025-08-05T00:00:00Z
http-transport: plain-http

package *
  split-sections: True
EOF
}

build() {
    _shellcheck_env
    cabal update
    cabal freeze
    cat cabal.project.freeze
    cabal build -j"$JOBS" exe:shellcheck
}

package() {
    _shellcheck_env
    install -Dm755 "$(cabal list-bin exe:shellcheck)" "$DESTDIR/usr/bin/shellcheck"
}
