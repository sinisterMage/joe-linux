# Not in the book: upstream stable, built with setuptools.
# Regenerate the optional native accelerators with Cython's Python 3.15 support.
# Optional WOFF/Graphite/interpolation backends are runtime extras, not auto-detected native links.
build() {
    export FONTTOOLS_WITH_CYTHON=1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist fonttools
}
