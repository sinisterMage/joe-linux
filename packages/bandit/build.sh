# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
# setup.py installs the manual page only when it has been built with Sphinx
# (doc/build/man), which the release does not include.
build() {
    # pbr takes the version from git, or failing that from PKG-INFO; state
    # it, as there is no git checkout.
    export PBR_VERSION="$PKG_VERSION"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist bandit
}
