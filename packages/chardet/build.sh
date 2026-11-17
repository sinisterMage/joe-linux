# Not in the book: the newest release on PyPI, built as a wheel and
# installed like the book's Python modules.
#
# The wheel is pure Python, upstream's default for a source build: the
# optional mypyc and Cython compilation of the detection pipeline is off
# unless HATCH_BUILD_HOOK_ENABLE_MYPYC and _CUSTOM are set, and it would
# need mypy and hatch-mypyc, which joe does not have. The modules then fall
# back to their plain Python loops, which give the same results.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist chardet
}
