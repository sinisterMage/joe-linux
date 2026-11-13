build() {
    # --disable-cache-build: never run the freshly built fc-cache from
    # "make install"; the trigger below builds the caches on the installed
    # system. json-c is only looked for to build a test program.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --disable-docs \
        --disable-cache-build
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # --disable-docs also skips the ready-made manual pages in the tarball.
    install -v -dm755 "$DESTDIR"/usr/share/man/man{1,3,5}
    install -v -m644 fc-*/*.1 "$DESTDIR/usr/share/man/man1"
    install -v -m644 doc/*.3 "$DESTDIR/usr/share/man/man3"
    install -v -m644 doc/fonts-conf.5 "$DESTDIR/usr/share/man/man5"

    # The system-wide cache lives in /var/cache/fontconfig, which is not
    # packaged.
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/joe-fontconfig.conf" <<'EOT'
d /var/cache/fontconfig 0755 root root -
EOT

    # Font caches follow every change to the font directories.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/35-fontconfig.zon" <<'EOT'
.{
    .name = "fontconfig cache",
    .paths = .{"usr/share/fonts/"},
    .exec = .{ "/usr/bin/fc-cache", "-s" },
}
EOT
}
