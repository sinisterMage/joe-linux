# The book's fonts page names these three families as fontconfig's first
# choice for Latin, Greek and Cyrillic text and links to Google Fonts'
# download button; the same fonts are released as zip files by the Noto
# project, one per family.
#
# Each zip holds every build of the family: about 70 static files, hinted
# and unhinted, as TTF and OTF, and the variable fonts. Only the variable
# fonts are installed: one file per family and slant covers every weight and
# width in a few megabytes. The "unhinted" build is the plain one; "full"
# and "googlefonts" merge Devanagari into Noto Sans.
unpack() {
    local zip
    for zip in NotoSans-v2.015 NotoSerif-v2.015 NotoSansMono-v2.014; do
        bsdtar -xf "$SOURCES/$zip.zip" --no-same-owner --no-same-permissions \
            '*/unhinted/variable*/*.ttf'
    done
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/noto"
    install -v -m644 \
        NotoSans/unhinted/variable-ttf/*.ttf \
        NotoSerif/unhinted/variable-ttf/*.ttf \
        NotoSansMono/unhinted/variable/*.ttf \
        "$DESTDIR/usr/share/fonts/noto"
}
