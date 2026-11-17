# Not in the book: the newest release on PyPI, built as a wheel with its
# poetry-core backend and installed like the book's Python modules. It
# installs the jws command.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist josepy
}
