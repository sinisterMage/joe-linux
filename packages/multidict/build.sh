# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
prepare() {
    # Upstream compiles its C extension with -Werror, so a new warning from a
    # newer GCC or Python header would fail the build; warnings stay
    # warnings here.
    sed -i '/^            "-Werror",$/d' setup.py
    if grep -q '"-Werror"' setup.py; then
        echo "multidict: -Werror is still in setup.py" >&2
        return 1
    fi
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist multidict
}
