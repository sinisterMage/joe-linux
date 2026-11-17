# Not in the book: the newest release on PyPI, built as INSTALL.txt says.
build() {
    # setup.py compiles the compiler's hot modules with Cython itself (the
    # copy in the source tree) unless told not to; that is upstream's
    # default and what makes it fast.
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    # cython, cythonize and cygdb, and the Cython package.
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist Cython
}
