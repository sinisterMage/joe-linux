# The book's fonts page describes these fonts without a download link; this
# is upstream's latest release of the ready-made TTF files. fontconfig's
# 30-metric-aliases.conf substitutes them for Arial, Times New Roman and
# Courier New (and Helvetica, Times and Courier).
package() {
    install -v -d -m755 "$DESTDIR/usr/share/fonts/liberation"
    install -v -m644 *.ttf "$DESTDIR/usr/share/fonts/liberation"
}
