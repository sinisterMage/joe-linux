# Following the book's Urllib3 (general/python-dependencies). The version
# comes from PKG-INFO (hatch-vcs).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist urllib3
}
