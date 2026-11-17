build() {
    # Generate yaml._yaml with Cython and require the LibYAML extension:
    # a compiler/link failure must not silently produce a pure Python wheel.
    export PYYAML_FORCE_CYTHON=1
    export PYYAML_FORCE_LIBYAML=1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist PyYAML
}
