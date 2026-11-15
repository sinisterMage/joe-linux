prepare() {
    # As the book does: setup.py takes its version from the calver module,
    # which joe Linux does not have, so the version is written in.
    sed -i '/calver/s/^/#/;$iversion="2026.6.1.19"' setup.py
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist trove-classifiers
}
