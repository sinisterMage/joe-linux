# Not in the book: the newest upstream release, with upstream's default
# configuration, built as its INSTALL says. Only the busybox binary itself
# is installed, as a rescue tool: run "busybox APPLET" or "busybox --list".
# The applet links ("make install") are not, because they would take the
# names of the real coreutils, util-linux, procps and other programs.
build() {
    make defconfig
    # tc still uses the CBQ queueing discipline, which the kernel and its
    # headers no longer have.
    sed -i 's/^CONFIG_TC=y$/# CONFIG_TC is not set/' .config
    make
    make docs/busybox.1
}

package() {
    install -Dm755 busybox "$DESTDIR/usr/bin/busybox"
    install -Dm644 docs/busybox.1 "$DESTDIR/usr/share/man/man1/busybox.1"
}
