# Not in the book: the newest upstream release, built as its README says.
build() {
    # 32-bit characters, as other distributions build it: the Python
    # bindings' tests assume them, and tables can then use characters
    # outside the Basic Multilingual Plane.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-ucs4 \
        --with-yaml
    make

    # The Python bindings are pure Python. make has written
    # python/louis/__init__.py with the library's soname filled in.
    cd python
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    # The library, the tools, their manual pages and the translation
    # tables in /usr/share/liblouis/tables.
    make DESTDIR="$DESTDIR" install

    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links python/dist louis
}
