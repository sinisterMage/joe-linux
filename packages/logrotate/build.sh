build() {
    # ACLs of rotated files are kept; there is no SELinux.
    ./configure --prefix=/usr \
        --with-acl \
        --without-selinux
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # The book's configuration. Its /etc/logrotate.d/sys.log is left out:
    # it rotates the log of sysklogd, and joe logs to the journal.
    install -d "$DESTDIR/etc/logrotate.d"
    cat > "$DESTDIR/etc/logrotate.conf" << "EOF"
# Begin /etc/logrotate.conf

# Rotate log files weekly
weekly

# Don't mail logs to anybody
nomail

# If the log file is empty, it will not be rotated
notifempty

# Number of backups that will be kept
# This will keep the 2 newest backups only
rotate 2

# Create new empty files after rotating old ones
# This will create empty log files, with owner
# set to root, group set to sys, and permissions 664
create 0664 root sys

# Compress the backups with gzip
compress

# No packages own lastlog or wtmp -- rotate them here
/var/log/wtmp {
    monthly
    create 0664 root utmp
    rotate 1
}

/var/log/lastlog {
    monthly
    rotate 1
}

# Some packages drop log rotation info in this directory
# so we include any file in it.
include /etc/logrotate.d

# End /etc/logrotate.conf
EOF
    chmod 0644 "$DESTDIR/etc/logrotate.conf"

    # The book's units, which run it daily. The timer is not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/logrotate.service" << "EOF"
[Unit]
Description=Runs the logrotate command
Documentation=man:logrotate(8)
DefaultDependencies=no
After=local-fs.target
Before=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/logrotate /etc/logrotate.conf
EOF
    cat > "$DESTDIR/usr/lib/systemd/system/logrotate.timer" << "EOF"
[Unit]
Description=Runs the logrotate command daily at 3:00 AM

[Timer]
OnCalendar=*-*-* 3:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}
