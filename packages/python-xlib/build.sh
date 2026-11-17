# Not in the book: the newest upstream release (2022), built as a wheel.

prepare() {
    # setup.py checks the setuptools version with pkg_resources, which
    # setuptools 82 removed, and asks for setuptools-scm, which it does not
    # use: the version comes from Xlib/__init__.py (setup.cfg).
    sed -i -e '/pkg_resources/d' \
        -e '/Check setuptools is recent/d' \
        -e '/setuptools_require/d' \
        -e "/setup_requires=/d" setup.py
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist python-xlib
}
