# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules. It is pure data and Python: the
# collections in ansible_collections, and the ansible-community command.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist ansible
}
