# Not in the book: the newest upstream release, built and installed with
# its Makefile as README.rst describes.
prepare() {
    # The manual pages and HTML manual come ready-made in docs/_build;
    # rebuilding them needs Sphinx, which joe Linux does not have. The
    # stamp makes "make install" use them as they are.
    touch doc
}

build() {
    # The optional C++ (XS) extension that speeds up lcov's data handling.
    # Without it lcov silently runs in pure Perl.
    make xs_lib
}

package() {
    make PREFIX=/usr CFG_DIR=/etc DESTDIR="$DESTDIR" install
}
