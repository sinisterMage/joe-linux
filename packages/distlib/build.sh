# Not in the book: the newest upstream release from PyPI, built like the
# book's setuptools modules.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist distlib

    # Launchers for Windows, used only there to make scripts executable.
    rm -v "$DESTDIR"/usr/lib/python3*/site-packages/distlib/*.exe
}
