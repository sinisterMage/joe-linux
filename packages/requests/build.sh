# Following the book's Requests (general/python-modules), with its
# recommended patch to use the system certificates rather than certifi.
prepare() {
    patch -Np1 -i "$SOURCES/requests-use_system_certs-2.patch"
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist requests
}
