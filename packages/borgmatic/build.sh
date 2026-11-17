# Not in the book: the newest release on PyPI, built as a wheel and installed
# like the book's Python modules.
build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --root "$DESTDIR" --find-links dist borgmatic

    # The completions borgmatic generates from its own argument parser, as
    # "borgmatic --bash-completion" and "--fish-completion" print them.
    local site
    site=$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    install -d "$DESTDIR/usr/share/bash-completion/completions" \
        "$DESTDIR/usr/share/fish/vendor_completions.d"
    PYTHONPATH="$DESTDIR$site" PYTHONDONTWRITEBYTECODE=1 \
        python3 -m borgmatic.commands.borgmatic --bash-completion \
        > "$DESTDIR/usr/share/bash-completion/completions/borgmatic"
    PYTHONPATH="$DESTDIR$site" PYTHONDONTWRITEBYTECODE=1 \
        python3 -m borgmatic.commands.borgmatic --fish-completion \
        > "$DESTDIR/usr/share/fish/vendor_completions.d/borgmatic.fish"

    # Upstream's sample units, for the system (as root) and for a user,
    # running the installed /usr/bin/borgmatic instead of a pip install in
    # /root/.local. The encrypted credential the system unit loads
    # (borgmatic.pw) does not exist until it is created, and a unit naming a
    # missing credential fails, so that line is left commented out. Neither
    # unit nor timer is enabled.
    install -d "$DESTDIR/usr/lib/systemd/system" "$DESTDIR/usr/lib/systemd/user"
    sed -e 's|/root/.local/bin/borgmatic|/usr/bin/borgmatic|' \
        -e 's|^LoadCredentialEncrypted=borgmatic.pw$|# LoadCredentialEncrypted=borgmatic.pw|' \
        sample/systemd/borgmatic.service > "$DESTDIR/usr/lib/systemd/system/borgmatic.service"
    install -m644 sample/systemd/borgmatic.timer "$DESTDIR/usr/lib/systemd/system/borgmatic.timer"
    sed -e 's|/root/.local/bin/borgmatic|/usr/bin/borgmatic|' \
        sample/systemd/borgmatic-user.service > "$DESTDIR/usr/lib/systemd/user/borgmatic.service"
    install -m644 sample/systemd/borgmatic-user.timer "$DESTDIR/usr/lib/systemd/user/borgmatic.timer"
    if grep -q '/root/.local' "$DESTDIR/usr/lib/systemd/system/borgmatic.service" \
        "$DESTDIR/usr/lib/systemd/user/borgmatic.service"; then
        echo "borgmatic: a unit still runs /root/.local/bin/borgmatic" >&2
        return 1
    fi
}
