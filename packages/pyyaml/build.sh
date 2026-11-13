build() {
    # The fast LibYAML binding (yaml._yaml, the CLoader/CDumper classes) is
    # written in Cython and the tarball does not carry the generated C, so
    # building it needs cython, which joe Linux does not have. Without
    # cython setup.py would try to compile a yaml/_yaml.c that is not there,
    # warn and fall back; say so up front instead. Everything in PyYAML
    # works without the binding, only slower.
    #
    # When cython exists: drop this variable, and add cython to
    # build_depends and libyaml to depends.
    export PYYAML_FORCE_LIBYAML=0
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist PyYAML
}
