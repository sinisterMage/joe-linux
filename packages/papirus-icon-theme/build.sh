# There is no book page. Papirus for light styles and Papirus-Dark for dark
# ones; Papirus-Light (dark icons for light panels) is left out, since no
# joe default uses it.
#
# Upstream inherits from KDE's Breeze, which joe does not package; GNOME's
# Adwaita stands in, before hicolor.
#
# Folders are teal, joe's accent, rather than Papirus' blue. That is what
# upstream's papirus-folders tool does: in each places directory, every
# icon named without a colour (folder.svg, user-home.svg) is a link to its
# blue variant, and is pointed at the teal one instead.
prepare() {
    sed -i 's/^Inherits=breeze-dark,hicolor$/Inherits=Adwaita,hicolor/; s/^Inherits=breeze,hicolor$/Inherits=Adwaita,hicolor/' \
        Papirus/index.theme Papirus-Dark/index.theme
    grep -qx 'Inherits=Adwaita,hicolor' Papirus/index.theme
    grep -qx 'Inherits=Adwaita,hicolor' Papirus-Dark/index.theme
    local dir link name target
    for dir in Papirus/*/places Papirus-Dark/*/places; do
        [[ -d $dir && ! -L $dir ]] || continue
        for link in "$dir"/*; do
            [[ -L $link ]] || continue
            name=${link##*/}
            [[ $name == *-blue* ]] && continue
            target=$(readlink "$link")
            [[ $target == *-blue* && $target != */* ]] || continue
            if [[ -e $dir/${target/-blue/-teal} ]]; then
                ln -sfn "${target/-blue/-teal}" "$link"
            fi
        done
    done
    [[ $(readlink Papirus/48x48/places/folder.svg) == folder-teal.svg ]]
}

package() {
    make DESTDIR="$DESTDIR" ICON_THEMES="Papirus Papirus-Dark" install
    # gtk3 owns gtk-update-icon-cache and rebuilds the caches of the themes
    # it ships; these are Papirus'. Without a cache, GTK reads every
    # directory of tens of thousands of icons as it starts.
    install -d "$DESTDIR/usr/lib/dave/triggers"
    cat > "$DESTDIR/usr/lib/dave/triggers/43-gtk-icon-cache-papirus.zon" <<'EOT'
.{
    .name = "Papirus icon cache",
    .paths = .{"usr/share/icons/Papirus/"},
    .exec = .{ "/usr/bin/gtk-update-icon-cache", "-qtf", "/usr/share/icons/Papirus" },
}
EOT
    cat > "$DESTDIR/usr/lib/dave/triggers/44-gtk-icon-cache-papirus-dark.zon" <<'EOT'
.{
    .name = "Papirus-Dark icon cache",
    .paths = .{"usr/share/icons/Papirus-Dark/"},
    .exec = .{ "/usr/bin/gtk-update-icon-cache", "-qtf", "/usr/share/icons/Papirus-Dark" },
}
EOT
}
