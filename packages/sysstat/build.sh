build() {
    # The book's directories. Spelled out beyond the book:
    # - the unit and sleep-hook directories, so that make install puts
    #   upstream's own units in place (sysstat.service with its collect,
    #   summary and rotate timers, and the suspend hook);
    # - --enable-copy-only, so that make install neither enables
    #   sysstat.service with systemctl nor edits a crontab;
    # - no lm-sensors and no Performance Co-Pilot, which are not packaged.
    sa_lib_dir=/usr/lib/sa \
    sa_dir=/var/log/sa \
    conf_dir=/etc/sysstat \
    ./configure --prefix=/usr \
        --disable-file-attr \
        --disable-compress-manpg \
        --disable-sensors \
        --disable-pcp \
        --enable-copy-only \
        --with-systemdsystemunitdir=/usr/lib/systemd/system \
        --with-systemdsleepdir=/usr/lib/systemd/system-sleep
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book removes the Also= lines from sysstat.service. They are kept:
    # they make "systemctl enable sysstat" enable the timers that collect
    # the data, and nothing is enabled here.
    test -f "$DESTDIR/usr/lib/systemd/system/sysstat-collect.timer"

    # The daily data files (/var is not packaged).
    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/sysstat.conf" << "EOF"
d /var/log/sa 0755 root root -
EOF
}
