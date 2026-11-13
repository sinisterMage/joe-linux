prepare() {
    # A privileged Python runs only sealed code files; see the patch's header.
    patch -Np1 -i /recipe/joe-sealed-code.patch
}

build() {
    # Profile-guided optimisation (--enable-optimizations) runs part of the test
    # suite during the build, which is slow and not reliable in the build
    # sandbox. It can return once builds are reproducible.
    # There is no system mpdecimal: build _decimal from the bundled copy
    # (the default would silently fall back to the slow pure-Python decimal).
    ./configure --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --without-system-libmpdec \
        --without-static-libpython
    make
}

package() {
    # "make install" would run ensurepip, which looks at the pip already
    # installed in the build root and, finding the same version there,
    # stages nothing. Install the bundled pip wheel ourselves with
    # --ignore-installed instead; ENSUREPIP_OPTIONS=install gives the same
    # pip3 and pip3.X scripts as "make install" does.
    make DESTDIR="$DESTDIR" ENSUREPIP=no install

    local whl
    whl=$(echo "$PWD"/Lib/ensurepip/_bundled/pip-*.whl)
    ENSUREPIP_OPTIONS=install PIP_CONFIG_FILE=/dev/null \
        LD_LIBRARY_PATH="$PWD${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        ./python -E "$whl/pip" install --no-cache-dir --no-index --no-deps \
        --ignore-installed --no-user --no-warn-script-location \
        --root "$DESTDIR" "$whl"

    # pip is part of the system Python here: do not nag root and do not
    # look for newer versions of pip.
    install -d "$DESTDIR/etc"
    cat > "$DESTDIR/etc/pip.conf" << EOF2
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF2
}
