# Not in the book: the newest release on PyPI of the 2.21 series, which the
# newest Ansible community package (ansible 14) requires (ansible-core
# ~= 2.21.6); 2.22 goes with ansible 15, still a release candidate. Built
# as a wheel and installed like the book's Python modules.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    # The manual pages, as upstream's release process makes them.
    # The man page generator refuses to run without a UTF-8 locale; the build
    # sandbox sets none.
    LC_ALL=C.UTF-8 python3 packaging/cli-doc/build.py man --output-dir man
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist ansible-core
    install -d "$DESTDIR/usr/share/man/man1"
    install -m644 man/*.1 "$DESTDIR/usr/share/man/man1/"
}
