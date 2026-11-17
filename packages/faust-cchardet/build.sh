# Not in the book: newest upstream PyPI source, verified against PyPI SHA256.
# The stable system uchardet lacks uchardet_get_n_candidates; keep upstream's
# bundled patched copy explicitly, rather than silently losing candidate APIs.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps \
        --config-settings=setup-args=-Dsystem-uchardet=disabled "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist faust-cchardet
}
