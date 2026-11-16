# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
build() {
    # On CPython setup.py compiles the module with mypyc unless told not to;
    # build it as pure Python, so mypy (listed in its build requirements for
    # that alone) is not needed.
    export PYTOKENS_USE_MYPYC=0
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pytokens
}
