# Following the book's Glad page, from the PyPI sdist (the same release as
# the book's GitHub archive). libplacebo generates its OpenGL loader with it
# at build time, from the specifications glad carries, offline.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist glad2
}
