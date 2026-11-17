# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules. The wheel carries upstream's manual pages
# (http.1, https.1, httpie.1) as data files for share/man/man1.
prepare() {
    patch -Np1 -i /recipe/detached-stdio.patch
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist httpie
    test -f "$DESTDIR/usr/share/man/man1/http.1"
}
