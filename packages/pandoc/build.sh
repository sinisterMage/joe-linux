# Not in the book: the newest upstream release, built with cabal as its
# INSTALL.md ("Compiling from source") says, the way upstream's own Linux
# release is built (linux/make_artifacts.sh): the pandoc-cli executable,
# with Lua filters and the server mode, and the data files (templates,
# reference documents) embedded in the binary.
#
# cabal downloads the Hackage libraries pandoc needs. cabal.project pins the
# Hackage index to the day after the release (index-state), so every build
# resolves the same versions; the resolved plan is printed into the build
# log. The libraries are linked into the binary statically, as cabal does
# by default.

_pandoc_env() {
    # cabal and GHC read and write UTF-8; the build sandbox's POSIX locale
    # makes them fail on the first non-ASCII character.
    export LANG=C.UTF-8 LC_ALL=C.UTF-8
    # cabal's configuration, Hackage index, downloads and package store
    # stay in the build directory, out of the shared build root.
    export HOME="$PWD/.home" CABAL_DIR="$PWD/.cabal"
}

prepare() {
    mkdir .home

    # Upstream's cabal.project without its WebAssembly section (which
    # fetches patched libraries from git) and without the bundled C zlib:
    # the system's is used.
    # - index-state: the Hackage index as it was the day after pandoc 3.14
    #   was released (2026-11-12).
    # - http-transport: the HTTP client built into cabal (Hackage is served
    #   over plain HTTP and cabal checks the index's signatures), so the
    #   build does not depend on curl and the CA certificates.
    # - embed_data_files (pandoc's default) and http (fetching resources),
    #   as upstream's release; split-sections for every package, as
    #   upstream's release builds pass -split-sections: the linker can then
    #   drop the unused parts of the libraries.
    cat > cabal.project << "EOF"
packages: .
          pandoc-lua-engine
          pandoc-server
          pandoc-cli
index-state: hackage.haskell.org 2026-11-13T00:00:00Z
http-transport: plain-http

constraints: skylighting-format-blaze-html >= 0.1.2.2,
             skylighting-format-context >= 0.1.0.2,
             auto-update >= 0.2.6,
             crypton >= 2.2

package pandoc
  flags: +http +embed_data_files

package pandoc-cli
  flags: +lua +server +repl

package *
  split-sections: True
EOF
}

build() {
    _pandoc_env
    cabal update
    cabal freeze
    cat cabal.project.freeze
    cabal build -j"$JOBS" exe:pandoc
}

package() {
    _pandoc_env
    local pandoc
    pandoc=$(cabal list-bin exe:pandoc)
    install -Dm755 "$pandoc" "$DESTDIR/usr/bin/pandoc"
    # As upstream's packages: the same program runs the server and the Lua
    # interpreter when called by these names.
    ln -s pandoc "$DESTDIR/usr/bin/pandoc-server"
    ln -s pandoc "$DESTDIR/usr/bin/pandoc-lua"

    local page
    for page in pandoc.1 pandoc-lua.1 pandoc-server.1; do
        install -Dm644 "pandoc-cli/man/$page" "$DESTDIR/usr/share/man/man1/$page"
    done

    # The completion scripts pandoc generates (--completion).
    install -d "$DESTDIR/usr/share/bash-completion/completions" \
        "$DESTDIR/usr/share/zsh/site-functions" \
        "$DESTDIR/usr/share/fish/vendor_completions.d"
    "$pandoc" --completion=bash > "$DESTDIR/usr/share/bash-completion/completions/pandoc"
    "$pandoc" --completion=zsh > "$DESTDIR/usr/share/zsh/site-functions/_pandoc"
    "$pandoc" --completion=fish > "$DESTDIR/usr/share/fish/vendor_completions.d/pandoc.fish"
}
