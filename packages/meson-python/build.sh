# Following the book's Meson_python (general/python-dependencies). The PyPI
# project is meson-python; it builds itself with its own backend.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist meson_python
}
