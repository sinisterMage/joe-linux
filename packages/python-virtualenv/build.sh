# Not in the book: the newest upstream release from PyPI (project virtualenv),
# built like the book's hatchling modules. The version comes from PKG-INFO
# (hatch-vcs). Upstream's own build hook (hatch_build.py) only writes an
# SBOM into the wheel.
#
# virtualenv seeds new environments from the pip and setuptools wheels it
# carries in virtualenv/seed/wheels/embed, so it works offline.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist virtualenv
}
