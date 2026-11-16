# Following the book's Midnight Commander page, with ncurses as the screen
# library: S-Lang, the book's recommendation, has no recipe here. Also off
# because their libraries have no recipe: the gpm mouse and Aspell spelling
# in the editor. The X11 support (reading modifier keys from an X server)
# and the ext2 undelete file system are left out as well.
build() {
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --enable-charset \
        --with-screen=ncurses \
        --with-search-engine=glib \
        --enable-vfs-sftp \
        --disable-vfs-undelfs \
        --disable-aspell \
        --without-gpm-mouse \
        --without-x \
        --disable-doxygen-doc
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
