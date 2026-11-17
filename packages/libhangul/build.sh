# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Loading keyboards from XML files at run time is experimental upstream
    # and off by default; the built-in keyboards are the same ones.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-external-keyboards
    make
}

package() {
    # The library, the hangul command line tool and the hanja dictionary
    # in /usr/share/libhangul.
    make DESTDIR="$DESTDIR" install
}
