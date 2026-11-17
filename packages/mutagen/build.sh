# Not in the book: the newest release on PyPI, built as a wheel and
# installed like the book's Python modules, with the manual pages of its
# command-line tools (mid3v2, mutagen-inspect, ...).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist mutagen
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 man/*.1 "$DESTDIR/usr/share/man/man1/"
}
