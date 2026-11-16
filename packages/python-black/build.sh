# Not in the book: the newest release on PyPI (project black), built as a
# wheel and installed like the book's Python modules. The version comes from
# PKG-INFO (hatch-vcs).
#
# Upstream's PyPI wheels are compiled with mypyc; the hatch-mypyc build hook
# is off by default (enable-by-default = false), so this build is pure Python
# (slower, but formats the same).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist black
}
