# Following the book's Msgpack (general/python-dependencies). The book lists
# Cython as required, but setup.py compiles msgpack/_cmsgpack.c, which the
# tarball carries already generated (Cython 3.2.5), and never runs Cython.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist msgpack
}
