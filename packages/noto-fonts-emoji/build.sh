# The book's fonts page does not list an emoji font. This is the font file
# as built by upstream, from the repository at the release tag (Unicode 18.0,
# font version 2.057); the source tarball is hundreds of megabytes of images
# and builds the font with tools that have no recipes.
#
# It is the bitmap (CBDT) build, which every renderer draws. fontconfig's
# 60-generic.conf already names "Noto Color Emoji" first for emoji.
unpack() {
    cp "$SOURCES/$PKG_SOURCE" NotoColorEmoji.ttf
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/noto-emoji"
    install -v -m644 NotoColorEmoji.ttf "$DESTDIR/usr/share/fonts/noto-emoji"
}
