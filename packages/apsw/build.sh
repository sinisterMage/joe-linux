# Not in the book: newest upstream PyPI source, verified against PyPI SHA256.
prepare() {
    # The PyPI configuration otherwise downloads and statically embeds SQLite.
    sed -i -e 's/fetch = True/fetch = False/' \
        -e 's/enable_all_extensions = True/enable_all_extensions = False/' setup.apsw
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist apsw
}
