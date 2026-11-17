# Following the book's GParted page.
build() {
    # The gparted script runs gpartedbin through pkexec, which keeps DISPLAY
    # and XAUTHORITY for it (the polkit action's allow_gui), so root reaches
    # the session's Xwayland through its authority file. --enable-xhost-root
    # would instead grant root access with xhost, which is not packaged.
    # The book's /dev/mapper dmraid support is off by default and stays off
    # (dmraid is not packaged).
    ./configure --prefix=/usr \
        --disable-static \
        --disable-xhost-root \
        --disable-libparted-dmraid
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book's edit of gparted.desktop to run "sudo -A" is left out:
    # authorisation is polkit's (usr/share/polkit-1/actions/org.gnome.gparted.policy).
}
