# Not in the book: upstream stable with its setuptools backend.
# SciPy 1.18.1 explicitly requires Pythran >=0.19.0 for Python 3.15.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pythran
}
