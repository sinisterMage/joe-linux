# Following the book's Sphinxcontrib-jsmath (general/python-dependencies),
# with its required patch for Sphinx 9.
#
# setup.py declares sphinxcontrib as an old-style namespace package, so the
# wheel leaves out sphinxcontrib/__init__.py and carries a -nspkg.pth file
# instead (it uses importlib, not pkg_resources); the other sphinxcontrib
# modules share the directory as a PEP 420 namespace.
prepare() {
    patch -Np1 -i "$SOURCES/sphinxcontrib-jsmath-1.0.1-sphinx9_fixes-1.patch"
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist sphinxcontrib-jsmath
}
