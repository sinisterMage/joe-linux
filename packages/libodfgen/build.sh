# Not in the book: the newest upstream release, built with its configure
# script, without its extra test programs, documentation or -Werror.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --disable-werror \
        --disable-test \
        --without-docs
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
