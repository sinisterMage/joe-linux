# Not in the book: the newest upstream release, built with the configure
# script in its release archive (the README is empty), as distributions do.
prepare() {
    # The cupshelpers module is installed with "setup.py install
    # --prefix=$(DESTDIR)$(prefix)", which records the staging directory
    # in the byte code; install it under --root instead.
    sed -i 's|setup.py install --prefix=$(DESTDIR)$(prefix)|setup.py install --root=$(DESTDIR) --prefix=$(prefix)|' Makefile.in
    grep -q 'setup.py install --root=$(DESTDIR) --prefix=$(prefix)' Makefile.in
}

build() {
    # --without-udev-rules: upstream's default. The rules would configure
    # a queue for every USB printer plugged in, through a C helper and a
    # systemd unit; ipp-usb covers IPP-over-USB printers.
    # --without-xmlto: the manual pages need xmlto, which has no recipe.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --without-udev-rules \
        --without-xmlto
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
