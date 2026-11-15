build() {
    # As the book does. libjte (Jigdo template export) does not exist;
    # ldconfig at install time would act on the build root.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-libacl \
        --enable-xattr \
        --enable-zlib \
        --disable-libjte \
        --disable-ldconfig-at-install
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
