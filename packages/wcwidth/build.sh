# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
build() {
    # The optional C extension (wcwidth._wcwidth_c, plain C against Python's
    # stable ABI, no libraries) is built. setup.py would quietly fall back to
    # the pure Python implementation when it fails to compile;
    # CIBUILDWHEEL=1 is upstream's switch that makes the extension
    # mandatory, so a failure stops the build instead.
    CIBUILDWHEEL=1 pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist wcwidth
}
