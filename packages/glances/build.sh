# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
#
# Left out: the web interface (glances -w and its REST API). It needs
# FastAPI and Uvicorn, which are not packaged, and the sdist carries the
# web UI only prebuilt (glances/outputs/static/public, a webpack bundle of
# its Vue sources). That directory and the sources are removed, so nothing
# prebuilt is installed; the terminal interface, the client/server mode
# (XML-RPC) and the exports are unaffected.
prepare() {
    rm -r glances/outputs/static
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    # This also installs upstream's manual page (docs/man/glances.1) and,
    # under usr/share/doc, which is not packaged, the configuration sample.
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist Glances

    # The system-wide configuration, where glances looks for it
    # (/etc/glances/glances.conf), as upstream's install documentation puts
    # it; every setting in it is upstream's default.
    install -Dm644 conf/glances.conf "$DESTDIR/etc/glances/glances.conf"

    # Completions, generated from glances's argument parser by shtab, as
    # upstream's documentation does (glances --print-completion SHELL).
    # Its log file goes to $XDG_CACHE_HOME, kept here rather than in the
    # shared build root's /root.
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    mkdir -p .cache
    export XDG_CACHE_HOME="$PWD/.cache"
    PYTHONPATH="$DESTDIR$site" python3 -m glances --print-completion bash > glances.bash
    PYTHONPATH="$DESTDIR$site" python3 -m glances --print-completion zsh > glances.zsh
    install -Dm644 glances.bash "$DESTDIR/usr/share/bash-completion/completions/glances"
    install -Dm644 glances.zsh "$DESTDIR/usr/share/zsh/site-functions/_glances"
}
