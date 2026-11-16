# Following the book's Charset-normalizer (general/python-dependencies). Its
# build backend compiles md.py and cd.py with mypyc only when
# CHARSET_NORMALIZER_USE_MYPYC=1, which is not set, so this is pure Python.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist charset-normalizer
}
