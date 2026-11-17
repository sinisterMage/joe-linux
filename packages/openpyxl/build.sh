# Not in the book: the newest stable upstream PyPI source release,
# built and installed as a wheel, without build isolation or dependency downloads.
# Upstream's default is pure Python (do not pass --with-cython). Explicit
# runtime dependencies enable the available lxml, defusedxml, NumPy and
# Pillow integrations rather than depending on the build root's contents.

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --prefix /usr --root "$DESTDIR" --find-links dist openpyxl
}
