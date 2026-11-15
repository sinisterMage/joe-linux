# Not in the book: the newest upstream release from PyPI, built like the
# book's hatchling modules. The version comes from PKG-INFO (hatch-vcs).
prepare() {
    # The python-sbom build hook only adds a software bill of materials to the
    # wheel, and joe Linux does not have it.
    sed -i '/^build.hooks.python-sbom/d' pyproject.toml
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist filelock
}
