# Not in the book: the newest upstream release, built with configure as its
# INSTALL.md says. gnome-remote-desktop stores its credentials with it.
build() {
    # The ESAPI's cryptography is OpenSSL (upstream's default); the FAPI
    # and the policy library are built, as their libraries have recipes.
    # TCTIs: everything upstream builds by default, including the
    # LetsTrust-TPM2Go USB one (libusb), except libtpms (no recipe) and
    # the FTDI SPI and I2C bridges (no libftdi). The Doxygen manual pages
    # are off; the hand-written ones for the TCTIs are installed.
    ./configure --prefix=/usr \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-runstatedir=/run \
        --with-sysusersdir=/usr/lib/sysusers.d \
        --with-tmpfilesdir=/usr/lib/tmpfiles.d \
        --with-udevrulesdir=/usr/lib/udev/rules.d \
        --with-udevrulesprefix=60- \
        --with-crypto=ossl \
        --enable-esys \
        --enable-fapi \
        --enable-policy \
        --enable-tcti-spi-ltt2go \
        --disable-tcti-libtpms \
        --disable-tcti-spi-ftdi \
        --disable-tcti-i2c-ftdi \
        --disable-unit \
        --disable-integration \
        --disable-doxygen-doc \
        --disable-static
    make
}

package() {
    # With DESTDIR set, the install hooks neither create the tss account
    # nor change ownership; the FAPI directories they make under var and
    # run are not packaged, tmpfiles.d makes them at boot.
    make DESTDIR="$DESTDIR" install

    # The account that owns /dev/tpm0 and whose group may use the kernel's
    # resource manager (/dev/tpmrm0), as 60-tpm-udev.rules sets up. Upstream
    # leaves the id to the system; it must be fixed here.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/tpm2-tss.conf" << "EOF"
g tss 69
u tss 69:69 "tss user for tpm2" / /usr/bin/false
EOF
}
