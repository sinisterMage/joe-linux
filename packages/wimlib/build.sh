# Not in the book: the newest upstream release, built as its README says.
# Mounting WIM images (wimmount) uses FUSE 3. Capturing from or applying to
# an unmounted NTFS volume needs libntfs-3g, which has no recipe.
build() {
    ./configure --prefix=/usr \
        --disable-static \
        --with-fuse \
        --without-ntfs-3g
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
