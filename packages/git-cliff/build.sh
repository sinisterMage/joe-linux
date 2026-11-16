# Not in the book: the newest upstream release, built with cargo as its
# release workflow (cd.yml) does, against the system's libgit2, zlib and
# zstd. Upstream publishes no checksum for the source archive.
# rust-toolchain.toml only matters to rustup and is ignored here.
build() {
    # Keep cargo's registry and download cache inside the build directory
    # rather than in root's home in the shared build root.
    export CARGO_HOME="$PWD/.cargo-home"
    # Link the libgit2 and libzstd that pkg-config finds rather than
    # building the copies inside libgit2-sys and zstd-sys. libz-sys uses the
    # system zlib by itself.
    export LIBGIT2_NO_VENDOR=1
    export ZSTD_SYS_USE_PKG_CONFIG=1
    # Every default feature but update-informer, which asks GitHub on each
    # run whether a newer git-cliff exists: the package manager is what
    # updates it. The remote integrations (GitHub, GitLab, Gitea, Bitbucket,
    # Azure DevOps) stay on.
    # --locked: build exactly the crate versions in upstream's Cargo.lock.
    cargo build --release --locked -p git-cliff \
        --no-default-features --features integrations

    # The manual page and shell completions, written by the two helper
    # programs the crate builds, as the release workflow runs them.
    mkdir -p man completions
    OUT_DIR=man target/release/git-cliff-mangen
    OUT_DIR=completions target/release/git-cliff-completions
}

package() {
    install -Dm755 target/release/git-cliff "$DESTDIR/usr/bin/git-cliff"
    install -Dm644 man/git-cliff.1 "$DESTDIR/usr/share/man/man1/git-cliff.1"
    install -Dm644 completions/git-cliff.bash "$DESTDIR/usr/share/bash-completion/completions/git-cliff"
    install -Dm644 completions/_git-cliff "$DESTDIR/usr/share/zsh/site-functions/_git-cliff"
    install -Dm644 completions/git-cliff.fish "$DESTDIR/usr/share/fish/vendor_completions.d/git-cliff.fish"
}
