# Following the book's SWIG page. configure also looks for the target
# languages' interpreters and compilers, but only for the test suite, which is
# not built: swig itself generates code for every language either way.
build() {
    ./configure --prefix=/usr \
        --with-pcre \
        --enable-ccache
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
