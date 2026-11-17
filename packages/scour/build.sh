# Following the book's Python Modules page (Scour), at its version; the
# source is the release's PyPI sdist (checked against PyPI's SHA-256) rather
# than the book's GitHub archive, whose file name it shares in build/src.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist scour
}
