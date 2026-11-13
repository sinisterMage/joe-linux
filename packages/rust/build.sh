# The stage0 toolchain x.py bootstraps from: src/stage0 in the source tarball
# names this date and version, and package.zon lists the matching tarballs.
_stage0_date=2026-08-20
_stage0_version=1.98.0

_rust_env() {
    # Let the vendored libssh2-sys and libsqlite3-sys crates use a system
    # library when pkg-config finds one (SQLite), falling back to their
    # bundled copy when it does not (libssh2).
    export LIBSSH2_SYS_USE_PKG_CONFIG=1
    export LIBSQLITE3_SYS_USE_PKG_CONFIG=1
    # cargo wants a home directory to write to even when every crate is
    # vendored; keep it out of the shared build root.
    export CARGO_HOME="$PWD/build/cargo-home"
}

prepare() {
    # x.py downloads a stage0 rustc, rust-std and cargo from
    # static.rust-lang.org unless it finds them, by file name, in its
    # download cache. Put them there; x.py and bootstrap then verify them
    # against the checksums in src/stage0 and never touch the network. All
    # the crates are already in vendor/.
    local c
    mkdir -p "build/cache/$_stage0_date"
    for c in rustc rust-std cargo; do
        cp "$SOURCES/$c-$_stage0_version-x86_64-unknown-linux-gnu.tar.xz" \
            "build/cache/$_stage0_date/"
    done

    # The book's bootstrap.toml, except: installed into /usr instead of
    # /opt/rustc-1.99.0 (so no /opt/rustc symlink and no profile.d script
    # to extend PATH), the crates must come from vendor/, and no
    # i686 target section.
    cat > bootstrap.toml << "EOF2"
# See bootstrap.toml.example for more possible options,
# and see src/bootstrap/defaults/bootstrap.dist.toml for a few options
# automatically set when building from a release tarball
# (unfortunately, we have to override many of them).

# Tell x.py that the editors have reviewed the content of this file
# and updated it to follow the major changes of the building system,
# so x.py will not warn users to review that information.
change-id = 160100

[llvm]
# When using the system installed copy of LLVM, prefer the shared libraries
link-shared = true

# If building the shipped LLVM source, only enable the x86 target
# instead of all the targets supported by LLVM.
targets = "X86"

[build]
description = "joe Linux"

# Omit the documentation to save time and space (the default is to build them).
docs = false

# Only install these extended tools. Cargo, clippy, rustdoc, and rustfmt
# are installed by a default rustup installation, and rust-src is needed
# to build the Rust code in Linux kernel (in case you need such a kernel
# feature).
tools = ["cargo", "clippy", "rustdoc", "rustfmt", "src"]

# Build only from the crates in vendor/, and fail rather than reach for
# the network if one is missing.
vendor = true

[install]
prefix = "/usr"
sysconfdir = "/etc"
docdir = "share/doc/rustc-1.99.0"

[rust]
channel = "stable"

# Enable the same optimizations as the official upstream build.
lto = "thin"
codegen-units = 1

# Don't build llvm-bitcode-linker which is only useful for the NVPTX
# backend that we don't enable.
llvm-bitcode-linker = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
EOF2
}

build() {
    _rust_env
    ./x.py build
}

package() {
    _rust_env
    DESTDIR="$DESTDIR" ./x.py install

    # Records kept by the installer script for its uninstall.sh; they are
    # full of $DESTDIR paths and the package manager does that job.
    rm -f "$DESTDIR"/usr/lib/rustlib/{components,install.log,rust-installer-version,uninstall.sh}
    rm -f "$DESTDIR"/usr/lib/rustlib/manifest-*

    # The book moves cargo's bash completion to where bash-completion
    # looks for it. (Its zsh completion is already in the right place with
    # the /usr prefix.)
    install -d "$DESTDIR/usr/share/bash-completion/completions"
    mv "$DESTDIR/etc/bash_completion.d/cargo" \
        "$DESTDIR/usr/share/bash-completion/completions/cargo"
    rmdir --ignore-fail-on-non-empty "$DESTDIR/etc/bash_completion.d" "$DESTDIR/etc"
}
