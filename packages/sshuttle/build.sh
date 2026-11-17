# Not in the book: the newest upstream release, built as a wheel from the
# sdist PyPI publishes.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    sphinx-build -b man docs build/man
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist sshuttle
    install -Dm644 build/man/sshuttle.1 "$DESTDIR/usr/share/man/man1/sshuttle.1"
}
