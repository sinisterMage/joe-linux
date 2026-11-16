# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
# pylint 4.1.4 accepts astroid 4.3.4 up to 4.4, and 4.3.4 is the newest.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist astroid
}
