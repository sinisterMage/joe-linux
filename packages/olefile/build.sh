# Not in the book: the newest stable upstream PyPI source release,
# built and installed as a wheel, without build isolation or dependency downloads.
unpack() {
    bsdtar -xf "$SOURCES/$PKG_SOURCE" --strip-components=1 \
        --no-same-owner --no-same-permissions
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --prefix /usr --root "$DESTDIR" --find-links dist olefile
}
