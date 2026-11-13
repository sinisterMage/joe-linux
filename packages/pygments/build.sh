prepare() {
    # Upstream builds with hatchling, which (with its own dependencies
    # pathspec, pluggy and trove-classifiers) is not part of joe Linux.
    # Pygments is pure Python and its metadata is all standard [project]
    # data, so setuptools can build the very same wheel: swap the build
    # backend and tell setuptools the two things hatchling was told in
    # [tool.hatch]: which package to ship and where the version is.
    sed -i \
        -e 's/^requires = \["hatchling[^]]*\]/requires = ["setuptools>=77"]/' \
        -e 's/^build-backend = "hatchling.build"/build-backend = "setuptools.build_meta"/' \
        pyproject.toml
    grep -q '^build-backend = "setuptools.build_meta"' pyproject.toml
    cat >> pyproject.toml << "EOF2"

[tool.setuptools.packages.find]
include = ["pygments", "pygments.*"]

[tool.setuptools.dynamic]
version = {attr = "pygments.__version__"}
EOF2
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist Pygments
}
