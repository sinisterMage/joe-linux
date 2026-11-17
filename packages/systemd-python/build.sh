# Not in the book: the newest upstream release, built as a wheel with
# meson-python, as its README says (236 moved from setup.py to Meson).
build() {
    pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist systemd-python
}
