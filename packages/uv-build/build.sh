# Not in the book: PyPI SHA256 verified. Upstream explicitly supports using
# the already source-built uv build-backend rather than compiling it twice.
prepare() {
    sed -i 's/^USE_UV_EXECUTABLE = False$/USE_UV_EXECUTABLE = True/' python/uv_build/__init__.py
    # This packaged variant invokes uv build-backend, whose metadata path is
    # a named option rather than uv-build's positional argument.
    patch -Np1 -i /recipe/native-metadata-option.patch
}

build() {
    PYTHONPATH="$PWD/python" python3 /recipe/test-backend.py
}

package() {
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    install -d "$DESTDIR$site"
    cp -a python/uv_build "$DESTDIR$site/"
    install -d "$DESTDIR$site/uv_build-$PKG_VERSION.dist-info"
    printf 'Metadata-Version: 2.1\nName: uv-build\nVersion: %s\n' "$PKG_VERSION" \
        > "$DESTDIR$site/uv_build-$PKG_VERSION.dist-info/METADATA"
}
