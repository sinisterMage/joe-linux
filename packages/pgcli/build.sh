# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pgcli
    # Upstream's bash completion, shipped in the sdist. It completes
    # databases and users by running psql.
    install -Dm644 pgcli-completion.bash "$DESTDIR/usr/share/bash-completion/completions/pgcli"
}
