# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
# mypy imports it (librt.internal) for its cache and AST formats.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist librt
}
