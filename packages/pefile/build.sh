# Not in BLFS: upstream's PyPI source release, built like the book's Python
# modules. fwupd-efi uses this to mark its firmware executable NX-compatible.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pefile
}
