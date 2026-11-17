# Not in the book: the newest upstream release, built as a Python package.
build() {
    # Build the C speedups or fail, instead of silently doing without.
    export BUILD_EXTENSION=yes
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist websockets
}
