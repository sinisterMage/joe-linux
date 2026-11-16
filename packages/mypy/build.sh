# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
#
# Upstream's PyPI wheels are compiled with mypyc; setup.py does that only
# with --use-mypyc or MYPY_USE_MYPYC=1, so this build is pure Python (slower,
# but behaves the same). The build-system requirements types-psutil and
# types-setuptools are only for that compiled build's self-check.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist mypy
}
