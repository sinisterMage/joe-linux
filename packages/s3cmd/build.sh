# Not in the book: the newest upstream release, built as a wheel and
# installed like the book's Python modules. setup.py adds the manual page
# (share/man/man1/s3cmd.1) as a data file.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist s3cmd
    test -f "$DESTDIR/usr/share/man/man1/s3cmd.1"
}
