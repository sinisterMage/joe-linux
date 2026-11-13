# The book's fonts page sends the reader to the noto-cjk release page for a
# monolithic .ttc with full coverage. This is the variable one, taken from
# the repository at the release tag Sans2.004: a single 31 MB collection
# with the five regional families (JP, KR, SC, TC, HK) in every weight. The
# static "super OTC" is three times the size, and the release's zip of the
# variable fonts is 250 MB because it repeats them in every packaging.
#
# Noto Sans Mono CJK (as much again) and Noto Serif CJK are left out:
# ideographs are the same in the Mono family, and a serif request falls
# back to these.
unpack() {
    cp "$SOURCES/$PKG_SOURCE" NotoSansCJK-VF.otf.ttc
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/noto-cjk"
    install -v -m644 NotoSansCJK-VF.otf.ttc "$DESTDIR/usr/share/fonts/noto-cjk"

    # All five families contain every glyph and claim every language, so
    # fontconfig has nothing to choose between them by: a Chinese user would
    # get Japanese or Korean letter forms at random. Put the family that
    # belongs to the language first, and give the rest a fixed order for
    # everyone else.
    #
    # The file sorts before 65-nonlatin.conf, whose own lists (which name
    # only the Korean family) would otherwise come first, and after
    # 60-latin.conf, so Latin text keeps its own fonts. system-ui is the
    # generic family that Adwaita Sans, the GNOME interface font, falls back
    # through.
    install -d "$DESTDIR/usr/share/fontconfig/conf.avail" "$DESTDIR/etc/fonts/conf.d"
    {
        echo '<?xml version="1.0"?>'
        echo '<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">'
        echo '<fontconfig>'
        echo '  <description>Choose the Noto Sans CJK family by language</description>'
        local generic rule lang family
        for generic in system-ui sans-serif serif monospace; do
            for rule in ja:JP ko:KR zh-cn:SC zh-sg:SC zh-tw:TC zh-hk:HK zh-mo:HK; do
                lang=${rule%:*} family="Noto Sans CJK ${rule#*:}"
                echo '  <match target="pattern">'
                echo "    <test name=\"lang\" compare=\"contains\"><string>$lang</string></test>"
                echo "    <test name=\"family\"><string>$generic</string></test>"
                echo "    <edit name=\"family\" mode=\"prepend\"><string>$family</string></edit>"
                echo '  </match>'
            done
            echo '  <alias>'
            echo "    <family>$generic</family>"
            echo '    <prefer>'
            for family in JP KR SC TC HK; do
                echo "      <family>Noto Sans CJK $family</family>"
            done
            echo '    </prefer>'
            echo '  </alias>'
        done
        echo '</fontconfig>'
    } > "$DESTDIR/usr/share/fontconfig/conf.avail/64-noto-cjk.conf"
    ln -sv ../../../usr/share/fontconfig/conf.avail/64-noto-cjk.conf "$DESTDIR/etc/fonts/conf.d/"
}
