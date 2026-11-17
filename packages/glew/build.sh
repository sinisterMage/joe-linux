# Following the book's GLEW page: libraries in /usr/lib (not lib64), no
# static library, installed under /usr rather than /usr/local.
prepare() {
    sed -i 's%lib64%lib%g' config/Makefile.linux
    sed -e '/glew.lib.static:/d' \
        -e '/0644 .*STATIC/d' \
        -e 's/glew.lib.static//' \
        -e 's|/local||' \
        -i Makefile
}

build() {
    make
}

package() {
    make DESTDIR="$DESTDIR" install.all
}
