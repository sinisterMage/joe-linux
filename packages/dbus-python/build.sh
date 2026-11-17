# Following the book's Python modules page (D-Bus Python), without the unit
# tests, which need tap.py.
build() {
    pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \
        -Csetup-args=-Dtests=disabled "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist dbus-python
}
