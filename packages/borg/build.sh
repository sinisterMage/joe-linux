# Not in the book: the newest stable release (1.4; 2.0 is still in beta),
# built as a wheel and installed like the book's Python modules.
prepare() {
    # The sdist carries the C files Cython generated (Cython 3.2.8), and
    # setup.py uses them when Cython cannot be imported; if Cython were in
    # the build root it would regenerate them. Keep the build independent of
    # that: Cython is not packaged.
    sed -i 's/^    from Cython.Build import cythonize$/    raise ImportError("Cython is not used here")/' setup.py
    grep -q '^    raise ImportError("Cython is not used' setup.py
}

build() {
    # The libraries are found through these variables rather than through
    # the "pkgconfig" Python module, which is not packaged.
    export BORG_OPENSSL_PREFIX=/usr \
        BORG_LIBLZ4_PREFIX=/usr \
        BORG_LIBZSTD_PREFIX=/usr \
        BORG_LIBXXHASH_PREFIX=/usr \
        BORG_LIBACL_PREFIX=/usr
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist borgbackup

    # Upstream's manual pages and shell completions, shipped in the sdist.
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 docs/man/*.1 "$DESTDIR/usr/share/man/man1/"
    install -Dm644 scripts/shell_completions/bash/borg "$DESTDIR/usr/share/bash-completion/completions/borg"
    install -Dm644 scripts/shell_completions/zsh/_borg "$DESTDIR/usr/share/zsh/site-functions/_borg"
    install -Dm644 scripts/shell_completions/fish/borg.fish "$DESTDIR/usr/share/fish/vendor_completions.d/borg.fish"
}
