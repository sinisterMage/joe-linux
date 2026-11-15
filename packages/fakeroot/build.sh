# Not in the book: the newest upstream release, built with meson as its
# INSTALL.md says.
build() {
    # libfakeroot is an LD_PRELOAD library and goes in its own directory,
    # /usr/lib/libfakeroot, where the fakeroot script looks for it (as on
    # Debian and Arch). SysV message queues, upstream's default IPC. The
    # translated manual pages need po4a, which joe Linux does not have;
    # the English ones are installed.
    meson setup build \
        --prefix=/usr \
        --libdir=lib/libfakeroot \
        --buildtype=release \
        -D ipc=sysv \
        -D dbformat=inode \
        -D docs=true
    ninja -C build
}

package() {
    DESTDIR="$DESTDIR" ninja -C build install
}
