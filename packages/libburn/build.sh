build() {
    # As the book does. libcdio (another way to reach drives) does not
    # exist; ldconfig at install time would act on the build root.
    ./configure --prefix=/usr \
        --disable-static \
        --disable-libcdio \
        --disable-ldconfig-at-install
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
