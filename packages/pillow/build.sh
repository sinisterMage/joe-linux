# Not in the book: the newest release on PyPI, built as a wheel with its
# setuptools backend and installed like the book's Python modules.

build() {
    # Every optional library that has a recipe is required, so a missing
    # one fails the build instead of quietly dropping a format.
    # Raqm and libimagequant use the system libraries rather than vendored
    # copies, for text layout and palette quantisation.
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps \
        -C parallel="$JOBS" \
        -C zlib=enable -C jpeg=enable -C tiff=enable -C freetype=enable \
        -C raqm=enable -C lcms=enable -C webp=enable -C jpeg2000=enable \
        -C xcb=enable -C avif=enable -C imagequant=enable \
        "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pillow
}
