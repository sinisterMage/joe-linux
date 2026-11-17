# Not in the book: the newest upstream release, built as its README says
# (setup.py, here as a wheel) and installed like the book's Python
# modules. The wheel carries the data files (interface definitions,
# translations, icons, desktop file, metainfo, manual page), which pip
# installs under /usr/share, where pdfarranger looks for them
# (sys.prefix/share).
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pdfarranger
}
