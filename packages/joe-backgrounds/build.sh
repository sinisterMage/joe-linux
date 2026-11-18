# joe's own artwork, in files/: teal waves, the installer's accent, one
# picture for light styles and one for dark. They are SVG, which GNOME
# draws at any size. The properties file lists them in Settings'
# Appearance page, beside GNOME's.
package() {
    local dir=$DESTDIR/usr/share/backgrounds/joe
    install -Dm644 /recipe/files/joe-l.svg "$dir/joe-l.svg"
    install -Dm644 /recipe/files/joe-d.svg "$dir/joe-d.svg"
    install -d "$DESTDIR/usr/share/gnome-background-properties"
    cat > "$DESTDIR/usr/share/gnome-background-properties/joe.xml" <<'EOT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>joe</name>
    <filename>/usr/share/backgrounds/joe/joe-l.svg</filename>
    <filename-dark>/usr/share/backgrounds/joe/joe-d.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#2a7a6f</pcolor>
    <scolor>#1c574f</scolor>
  </wallpaper>
</wallpapers>
EOT
}
