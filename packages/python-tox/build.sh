# Not in the book: the newest release on PyPI (project tox), built as a
# wheel and installed like the book's Python modules. The version comes from
# PKG-INFO (hatch-vcs); the wheel carries the manual page as data
# (usr/share/man/man1/tox.1).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist tox
}
