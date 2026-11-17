# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules, as its INSTALL.md describes. The wheel
# carries the translations, the desktop file, the icons and the AppStream
# metadata (setup.py's build step makes them).
#
# The update check is switched off (PICARD_DISABLE_AUTOUPDATE, upstream's
# switch for distributions): updates come from dave.
build() {
    PICARD_DISABLE_AUTOUPDATE=1 \
        pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    # picard-cli's shell completions, generated with shtab.
    python3 setup.py build_completions --output-dir build/completions
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist picard
    install -Dm644 build/completions/picard-cli \
        "$DESTDIR/usr/share/bash-completion/completions/picard-cli"
    install -Dm644 build/completions/_picard-cli \
        "$DESTDIR/usr/share/zsh/site-functions/_picard-cli"
    install -Dm644 build/completions/picard-cli.fish \
        "$DESTDIR/usr/share/fish/vendor_completions.d/picard-cli.fish"
}
