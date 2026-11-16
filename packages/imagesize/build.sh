# Following the book's Imagesize (general/python-dependencies). PyPI has
# 2.0.1; the book's version is used.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist imagesize
}
