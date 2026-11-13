build() {
    mkdir build
    cd build
    # The book passes update-mimedb=true to build the database while
    # installing; here the trigger below builds it on the installed system,
    # so the generated files are not packaged. No xmlto for the
    # specification.
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        -D update-mimedb=false \
        -D build-tools=true \
        -D build-translations=true \
        -D build-tests=false \
        -D build-spec=false
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The MIME database is compiled from usr/share/mime/packages/*.xml,
    # whichever package ships them.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/32-shared-mime-info.zon" <<'EOT'
.{
    .name = "MIME type database",
    .paths = .{"usr/share/mime/"},
    .exec = .{ "/usr/bin/update-mime-database", "/usr/share/mime" },
}
EOT
}
