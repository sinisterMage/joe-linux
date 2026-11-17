# Not in the book (its tesseract page installs no language data): the
# English model and the orientation and script detection model (osd) of
# upstream's latest tessdata_fast release, where tesseract looks for them
# (its default prefix, /usr/share/tessdata).
unpack() {
    :
}

package() {
    install -v -d -m755 "$DESTDIR/usr/share/tessdata"
    install -v -m644 "$SOURCES/tessdata_fast-4.1.0-eng.traineddata" "$DESTDIR/usr/share/tessdata/eng.traineddata"
    install -v -m644 "$SOURCES/tessdata_fast-4.1.0-osd.traineddata" "$DESTDIR/usr/share/tessdata/osd.traineddata"
}
