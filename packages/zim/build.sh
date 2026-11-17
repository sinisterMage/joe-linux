# Not in the book: the newest upstream release, built with its setup.py
# as the README says (here as a wheel, installed like the book's Python
# modules). setup.py's build step writes the manual page and compiles the
# translations; its data files (help notebook, plugins' data, icons,
# desktop file, MIME type, metainfo, manual page) go under /usr/share,
# where zim finds them through the XDG data directories.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist zim
}
