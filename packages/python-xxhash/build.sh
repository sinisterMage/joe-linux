# Not in the book: the newest release on PyPI, built as a wheel and
# installed like the book's Python modules.
build() {
    export XXHASH_LINK_SO=1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist xxhash
}
