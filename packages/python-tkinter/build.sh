# Not a page of the book: Python is configured as the python package
# configures it, but with Tk available, and only the _tkinter extension that
# results is packaged (other distributions split python-tkinter the same
# way). It is kept out of python so that every Python installation does not
# carry Tk and X11's libraries.
build() {
    ./configure --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --without-system-libmpdec \
        --without-static-libpython
    make
}

package() {
    local module
    module=$(find build -name '_tkinter.cpython-*.so' -print -quit)
    [[ -n $module ]] || { echo "_tkinter was not built" >&2; return 1; }
    install -Dm755 "$module" "$DESTDIR/usr/lib/python3.15/lib-dynload/${module##*/}"
}
