# Not in the book: the newest release on PyPI, built as a wheel and
# installed like the book's Python modules. The sdist carries
# .separate_namespace, so the package is Cryptodome (not Crypto) and does
# not collide with pycryptodome.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pycryptodomex
}
