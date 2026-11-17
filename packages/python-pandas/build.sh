# Not in the book: upstream stable, using its Meson backend.
# Python 3.15 is explicitly supported in pyproject.toml; Cython 3.3 regenerates extensions.
# Optional I/O engines and accelerators are runtime extras, not auto-linked build dependencies.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist pandas
}
