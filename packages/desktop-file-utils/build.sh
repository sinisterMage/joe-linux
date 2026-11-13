build() {
    mkdir build
    cd build
    meson setup .. \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install

    # The book creates /usr/share/applications and builds its cache here.
    # An empty directory is not packaged; the trigger builds mimeinfo.cache
    # as soon as a package installs a desktop entry.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/33-desktop-file-utils.zon" <<'EOT'
.{
    .name = "desktop entry MIME cache",
    .paths = .{"usr/share/applications/"},
    .exec = .{ "/usr/bin/update-desktop-database", "-q" },
}
EOT
}
