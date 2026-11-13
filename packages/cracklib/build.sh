build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-default-dict=/usr/lib/cracklib/pw_dict \
        --with-zlib \
        --with-python
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The recommended word list, and the dictionary compiled from it.
    install -v -m755 -d "$DESTDIR/usr/share/dict" "$DESTDIR/usr/lib/cracklib"
    xzcat "$SOURCES/cracklib-words-2.10.4.xz" \
        > "$DESTDIR/usr/share/dict/cracklib-words"
    ln -v -sf cracklib-words "$DESTDIR/usr/share/dict/words"
    # The book adds the machine's host name here; a package can only know the
    # distribution's default one.
    echo joe > "$DESTDIR/usr/share/dict/cracklib-extra-words"

    # create-cracklib-dict writes to the compiled-in location unless told
    # otherwise, and the tools it runs are the ones just staged.
    PATH="$DESTDIR/usr/sbin:$PATH" LD_LIBRARY_PATH="$DESTDIR/usr/lib" \
        create-cracklib-dict -o "$DESTDIR/usr/lib/cracklib/pw_dict" \
        "$DESTDIR/usr/share/dict/cracklib-words" \
        "$DESTDIR/usr/share/dict/cracklib-extra-words"
}
