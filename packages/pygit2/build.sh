# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules, against the system libgit2 (LIBGIT2 names
# its prefix; upstream's default is /usr/local).
build() {
    LIBGIT2=/usr pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pygit2
}
