# Not in the book: the newest upstream release from PyPI, built like the
# book's setuptools modules. The version comes from PKG-INFO.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist libarchive-c
}
