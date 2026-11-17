# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Update checks are off: joe's packages are updated by dave. pugixml is
    # the system's. Internationalised domain names are resolved by glibc's
    # getaddrinfo (AI_IDN), so libidn is not used. Storj needs libuplink,
    # which is not packaged.
    ./configure --prefix=/usr \
        --disable-static \
        --enable-locales \
        --enable-gui \
        --enable-ftp \
        --enable-sftp \
        --disable-storj \
        --disable-manualupdatecheck \
        --disable-autoupdatecheck \
        --with-pugixml=system \
        --with-dbus \
        --with-wx-config=/usr/bin/wx-config
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The AppStream file goes where AppStream looks for it now.
    install -d "$DESTDIR/usr/share/metainfo"
    mv "$DESTDIR/usr/share/appdata/filezilla.appdata.xml" "$DESTDIR/usr/share/metainfo/"
    rmdir "$DESTDIR/usr/share/appdata"
}
