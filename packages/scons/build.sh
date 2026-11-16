# Following the book's SCons page (general/scons).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist SCons
    # The manual pages (scons, sconsign, scons-time) ship prebuilt at the top
    # of the tarball. The book installs them 664; 644 here.
    install -vdm755 "$DESTDIR/usr/share/man/man1"
    install -vm644 ./*.1 "$DESTDIR/usr/share/man/man1"
}
