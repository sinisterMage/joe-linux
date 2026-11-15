# Not in the book: upstream's source release, built with Hadrian as
# INSTALL.md and hadrian/README.md describe, and installed the way upstream
# makes its own releases: Hadrian assembles a binary distribution
# (binary-dist-dir) and its "./configure && make install" installs it.
#
# 9.12.4 rather than the newer 9.14.1: cabal-install's newest release ships
# its bootstrap plan for 9.12.4 and none for 9.14, and Stackage builds the
# Hackage libraries ShellCheck needs with 9.12.4.
#
# Everything is built offline. The bootstrap compiler is upstream's 9.10.1
# for Debian 12, used only to build. Hadrian is a Haskell program too, and
# hadrian/bootstrap/bootstrap.py compiles it with that compiler from the
# Hackage sources GHC publishes for the purpose.
#
# Choices, stated:
# - release flavour (upstream's own) without the profiling libraries, which
#   would nearly double the build; the vanilla (static) and dynamic
#   libraries are both installed, as upstream installs them.
# - --docs=none: the manual and the man page need Sphinx, which joe lacks.
#   The library documentation (Haddock) is left out with them.
# - --hash-unit-ids, as upstream's releases: installed packages get unit
#   ids that change with their ABI.
# - joe's libffi rather than the copy in libffi-tarballs/.
# - --disable-ld-override: configure would otherwise make every link go
#   through ld.lld when lld happens to be in the build root, and GHC would
#   then need lld at run time.
# - no NUMA support: joe does not package numactl.

_ghc_stage0_version=9.10.1

_ghc_env() {
    # GHC, Cabal and Hadrian read and write UTF-8 (sources, package
    # descriptions, Shake's output) and fail on the first non-ASCII
    # character in the build sandbox's POSIX locale.
    export LANG=C.UTF-8 LC_ALL=C.UTF-8
    # Keep anything written to a home directory out of the shared build
    # root's /root.
    export HOME="$PWD/.home"
    # Upstream's bootstrap compiler (ghc and its terminfo and haskeline
    # libraries) was linked on Debian against libtinfo.so.6. joe's ncurses
    # is LFS's: one library, libncursesw.so.6, which has the same terminfo
    # functions. Give the bootstrap compiler, and only it, a private name for
    # it. glibc accepts the unversioned symbols, printing "no version
    # information available" on each run of the bootstrap ghc.
    export LD_LIBRARY_PATH="$PWD/.stage0-compat"
}

prepare() {
    mkdir .home .stage0-dist .stage0-compat .hadrian-bootstrap
    tar -xf "$SOURCES/ghc-$_ghc_stage0_version-x86_64-deb12-linux.tar.xz" -C .stage0-dist \
        --strip-components=1 --no-same-owner --no-same-permissions
    ln -s /usr/lib/libncursesw.so.6 .stage0-compat/libtinfo.so.6
}

build() {
    _ghc_env
    local top="$PWD" stage0="$PWD/.stage0"

    # The bootstrap compiler, installed into the build directory as its
    # INSTALL file says: configure writes its settings for this machine's
    # toolchain (DESTDIR, which the build environment exports, must not
    # apply to it). -j1: the bindist's install rules are not written for
    # parallel make.
    (
        cd .stage0-dist
        ./configure --prefix="$stage0" --disable-ld-override
        env -u DESTDIR make -j1 install
    )
    rm -rf .stage0-dist

    # Hadrian. With -s, bootstrap.py unpacks the sources tarball, takes its
    # plan-bootstrap.json and checks every package against it, and downloads
    # nothing; upstream's CI bootstraps this release the same way with this
    # compiler (test-bootstrap in .gitlab-ci.yml). It works in ./_build,
    # which is also Hadrian's build directory, so it runs in a directory of
    # its own. (Not python3 -I: the script finds the Hadrian sources from its
    # own location in sys.path.)
    (
        cd .hadrian-bootstrap
        python3 "$top/hadrian/bootstrap/bootstrap.py" \
            -w "$stage0/bin/ghc" \
            -s "$SOURCES/ghc-$PKG_VERSION-hadrian-bootstrap-sources-$_ghc_stage0_version.tar.gz" \
            --no-archive
    )

    ./configure GHC="$stage0/bin/ghc" \
        --prefix=/usr \
        --with-system-libffi \
        --disable-numa \
        --disable-ld-override

    .hadrian-bootstrap/_build/bin/hadrian -j"$JOBS" \
        --flavour=release+no_profiled_libs \
        --docs=none \
        --hash-unit-ids \
        binary-dist-dir
}

package() {
    _ghc_env

    # bash-completion's directory, as Hadrian's bindist carries the script
    # but its Makefile does not install it.
    install -Dm644 utils/completion/ghc.bash \
        "$DESTDIR/usr/share/bash-completion/completions/ghc"

    # Installs /usr/lib/ghc-9.12.4/{bin,lib} and wrapper scripts in
    # /usr/bin, and recaches the package database in $DESTDIR. The
    # bindist's configure detects the toolchain again for the installed
    # settings file, so it gets the same linker choice.
    cd _build/bindist/ghc-"$PKG_VERSION"-*/
    ./configure --prefix=/usr --disable-ld-override
    make -j1 DESTDIR="$DESTDIR" install

    # The package database's cache is not packaged but made by a trigger,
    # after this and every later change to the database: a packaged file is
    # sealed and so read-only, and ghc-pkg must be able to rewrite the cache
    # (and lock it to do so). Made at install time it is also newer than
    # the database, which it must be, or ghc-pkg calls it out of date.
    rm "$DESTDIR/usr/lib/ghc-$PKG_VERSION/lib/package.conf.d/package.cache" \
        "$DESTDIR/usr/lib/ghc-$PKG_VERSION/lib/package.conf.d/package.cache.lock"
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/50-ghc-pkg.zon" <<EOT
.{
    .name = "GHC package database",
    .paths = .{"usr/lib/ghc-$PKG_VERSION/lib/package.conf.d/"},
    .exec = .{ "/usr/bin/ghc-pkg", "recache", "--global" },
}
EOT
}
