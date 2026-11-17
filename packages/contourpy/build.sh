# Not in the book: upstream stable with its Meson backend.
# pyproject.toml declares Python 3.15 support and builds cp315 wheels.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist contourpy
}
