# Not in the book: the newest upstream release, built as its INSTALL says.
prepare() {
    # The shipped configure (Autoconf 2.59) misdetects functions with a
    # current compiler, setproctitle among them; regenerate it.
    autoreconf -fi
}

build() {
    # As Arch Linux does: some of configure's tests call functions they do
    # not declare (printf in the __progname check), which GCC 16 refuses by
    # default. libnsl is not wanted: glibc itself has gethostbyname.
    CFLAGS="-O2 -Wno-implicit-function-declaration" \
    ac_cv_lib_nsl_gethostbyname=no \
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --with-ssh=/usr/bin/ssh
    make
}

package() {
    install -Dm755 autossh "$DESTDIR/usr/bin/autossh"
    install -Dm644 autossh.1 "$DESTDIR/usr/share/man/man1/autossh.1"
    # The example wrappers (a host tunnel script and rscreen).
    install -Dm644 autossh.host "$DESTDIR/usr/share/autossh/examples/autossh.host"
    install -Dm644 rscreen "$DESTDIR/usr/share/autossh/examples/rscreen"
}
