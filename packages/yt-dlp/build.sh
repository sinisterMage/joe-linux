# Not in the book: the newest upstream release, built as a Python package.
# The source tarball carries the generated lazy extractors, the manual page
# and the bash, zsh and fish completions, which the wheel installs.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist yt-dlp

    # yt-dlp enables only Deno as a JavaScript runtime by default, and joe
    # packages Node.js instead. The system configuration file adds it;
    # --no-js-runtimes or --ignore-config undo it.
    install -d "$DESTDIR/etc"
    cat > "$DESTDIR/etc/yt-dlp.conf" << "EOT"
# System-wide options for yt-dlp, read before the user's own configuration.
# Solve YouTube's JavaScript challenges with Node.js (yt-dlp enables only
# Deno by default).
--js-runtimes node
EOT
}
