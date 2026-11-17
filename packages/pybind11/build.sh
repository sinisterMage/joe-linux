# Not in the book: the newest release on PyPI, built as a wheel with its
# scikit-build-core backend and installed like the book's Python modules.
build() {
    # CMake stages the wheel itself, not under the package's exported DESTDIR.
    env -u DESTDIR pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pybind11
}
