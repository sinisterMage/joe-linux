# Not in the book: the newest upstream release. Its setup.py uses
# python-distutils-extra, as its README says; it is built as a wheel.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist soundconverter
    # setup.py runs glib-compile-schemas on the directory it installs its
    # schema into; the compiled cache belongs to glib's trigger.
    rm -f "$DESTDIR/usr/share/glib-2.0/schemas/gschemas.compiled"
}
