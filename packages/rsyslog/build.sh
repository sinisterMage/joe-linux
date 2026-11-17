# Not in the book: the newest upstream release, built as its INSTALL says.
build() {
    # Inputs: the systemd journal (imjournal), files, plain TCP and
    # statistics, besides the built-in UDP, TCP and kernel ones. Outputs:
    # the journal, programs, stdout, Unix sockets, mail, HTTP and
    # Elasticsearch. TLS through OpenSSL and GnuTLS, GSSAPI, encrypted
    # (libgcrypt) and zstd-compressed log files, YAML configuration, and
    # capability dropping (libcap-ng). The modules whose libraries have no
    # recipe stay off, as they are by default: RELP, liblognorm
    # (mmnormalize), Kafka, MaxMind, SNMP, libdbi, czmq, RabbitMQ, MongoDB,
    # Mbed TLS, wolfSSL and the rest; so do the MySQL, PostgreSQL and
    # Redis outputs, whose client libraries come with their servers or are
    # not wanted by a logger. The manual pages ship ready-made.
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --disable-Werror \
        --enable-libsystemd=yes \
        --enable-imjournal \
        --enable-omjournal \
        --enable-libyaml \
        --enable-libcap-ng \
        --enable-uuid \
        --enable-regexp \
        --enable-openssl \
        --enable-gnutls \
        --enable-libgcrypt \
        --enable-libzstd \
        --enable-gssapi-krb5 \
        --enable-fmhttp \
        --enable-imfile \
        --enable-imptcp \
        --enable-impstats \
        --enable-impstats-push \
        --enable-omprog \
        --enable-omstdout \
        --enable-omuxsock \
        --enable-mail \
        --enable-omhttp \
        --enable-elasticsearch \
        --enable-mmjsonparse \
        --enable-mmanon \
        --enable-mmutf8fix \
        --enable-mmfields \
        --enable-mmpstrucdata \
        --enable-mmsequence \
        --enable-mmcount \
        --enable-pmlastmsg \
        --disable-mysql \
        --disable-pgsql \
        --disable-libdbi \
        --disable-snmp \
        --disable-relp \
        --disable-mmnormalize \
        --disable-imkafka \
        --disable-omkafka \
        --disable-omhiredis \
        --disable-imhiredis \
        --disable-mbedtls \
        --disable-wolfssl \
        --disable-generate-man-pages
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Upstream's Red Hat configuration (platform/redhat/rsyslog.conf) as
    # Fedora runs it: messages come from the journal through imjournal,
    # which keeps its position in /var/lib/rsyslog, and the local syslog
    # socket is not used, so journald (ForwardToSyslog=no by default) and
    # rsyslog do not both read it. The kernel's messages are in the
    # journal too, so imklog is not loaded.
    install -d "$DESTDIR/etc/rsyslog.d"
    sed -e '/^module(load="imuxsock")/,/^module(load="imklog")/c\
module(load="imuxsock"    # provides support for local system logging (e.g. via logger command)\
       SysSock.Use="off") # Turn off message reception via local log socket;\
                          # local messages are retrieved through imjournal now.\
module(load="imjournal"             # provides access to the systemd journal\
       UsePid="system"              # PID number is that of the process the journal entry originates from\
       FileCreateMode="0644"        # Set the access permissions for the state file\
       StateFile="imjournal.state") # File to store the position in the journal' \
        -e '/^#### GLOBAL DIRECTIVES ####/a\
\
# Where to place auxiliary files (the journal position, queues)\
global(workDirectory="/var/lib/rsyslog")' \
        platform/redhat/rsyslog.conf > "$DESTDIR/etc/rsyslog.conf"
    chmod 644 "$DESTDIR/etc/rsyslog.conf"

    install -d "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/tmpfiles.d/rsyslog.conf" << "EOT"
d /var/lib/rsyslog 0700 root root -
EOT

    # The release tarball no longer carries upstream's unit; this is the
    # one Fedora ships. It is not enabled, and it is not an alias of
    # syslog.service: rsyslog reads the journal instead of the socket
    # journald would forward to.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/rsyslog.service" << "EOT"
[Unit]
Description=System Logging Service
Wants=network.target network-online.target
After=network.target network-online.target
Documentation=man:rsyslogd(8)
Documentation=https://www.rsyslog.com/doc/

[Service]
Type=notify
ExecStart=/usr/sbin/rsyslogd -n -iNONE
ExecReload=/usr/bin/kill -HUP $MAINPID
UMask=0066
StandardOutput=null
Restart=on-failure
# Many files may be monitored at once.
LimitNOFILE=16384

[Install]
WantedBy=multi-user.target
EOT
}
