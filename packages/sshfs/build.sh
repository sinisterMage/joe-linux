# Following the book's sshfs page, with its optional docutils, whose
# rst2man makes the manual page. Installing also links mount.sshfs and
# mount.fuse.sshfs in /usr/sbin, for mount -t fuse.sshfs and fstab.
build() {
    mkdir build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
