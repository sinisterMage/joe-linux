# Following the book's Apache page.
#
# One change from the book: the document root, and the apache account's
# home, is /var/www rather than /srv/www. /var is the subvolume every
# deployment shares, so rolling the system back never rolls a web site
# back; /srv belongs to each deployment. /var is not packaged, so upstream's
# "It works!" page is not installed: the directory is made empty at boot.
prepare() {
    patch -Np1 -i "$SOURCES/httpd-blfs_layout-1.patch"

    sed '/dir.*CFG_PREFIX/s@^@#@' -i support/apxs.in

    sed -e '/HTTPD_ROOT/s:${ap_prefix}:/etc/httpd:' \
        -e '/SERVER_CONFIG_FILE/s:${rel_sysconfdir}/::' \
        -e '/AP_TYPES_CONFIG_FILE/s:${rel_sysconfdir}/::' \
        -i configure

    sed -e '/<Layout BLFS>/,/<\/Layout>/s@/srv/www@/var/www@' -i config.layout
    sed -e 's@"/srv/www"@"/var/www"@' -i include/httpd.h
}

build() {
    # The book's flags, with the suexec document root moved as above. The
    # modules that need a library are named, so that a missing one stops
    # configure instead of quietly dropping the module; mod_systemd, which
    # "all" leaves out, is built too (it only notifies systemd when the
    # unit is Type=notify). Off: mod_socache_dc (distcache has no recipe).
    ./configure --enable-authnz-fcgi \
        --enable-layout=BLFS \
        --enable-mods-shared="all cgi" \
        --enable-mpms-shared=all \
        --enable-suexec=shared \
        --with-apr=/usr/bin/apr-1-config \
        --with-apr-util=/usr/bin/apu-1-config \
        --with-pcre=/usr/bin/pcre2-config \
        --with-suexec-bin=/usr/lib/httpd/suexec \
        --with-suexec-caller=apache \
        --with-suexec-docroot=/var/www \
        --with-suexec-uidmin=100 \
        --with-suexec-userdir=public_html \
        --with-suexec-logfile=/var/log/httpd/suexec.log \
        --enable-ssl=shared \
        --enable-md=shared \
        --enable-http2=shared \
        --enable-proxy-http2=shared \
        --enable-deflate=shared \
        --enable-brotli=shared \
        --enable-lua=shared \
        --enable-xml2enc=shared \
        --enable-proxy-html=shared \
        --enable-ldap=shared \
        --enable-authnz-ldap=shared \
        --enable-session-crypto=shared \
        --enable-systemd=shared \
        --disable-socache-dc \
        --with-ssl=/usr \
        --with-z=/usr \
        --with-brotli=/usr \
        --with-nghttp2=/usr \
        --with-curl=/usr \
        --with-jansson=/usr \
        --with-lua=/usr \
        --with-libxml2=/usr
    make
}

package() {
    # Serially: its install rules create the same directories from parallel
    # jobs with a mkdir that fails if another job got there first.
    make -j1 DESTDIR="$DESTDIR" install

    # The book: suexec moves out of the path and is set-uid root, runnable
    # by the apache group only (4754). Files are packaged root-owned, so
    # the group is given at boot by tmpfiles.d below.
    mv "$DESTDIR/usr/sbin/suexec" "$DESTDIR/usr/lib/httpd/suexec"
    chmod 4754 "$DESTDIR/usr/lib/httpd/suexec"

    # The account the book creates (groupadd -g 25, useradd -u 25).
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/apache.conf" << "EOT"
g apache 25
u apache 25:25 "Apache Server" /var/www /usr/bin/false
EOT
    # The document root (the book's chown -R apache:apache /srv/www), the
    # log and disk cache directories make install would create, and
    # blfs-systemd-units' /run/httpd for the pid file.
    cat > "$DESTDIR/usr/lib/tmpfiles.d/apache.conf" << "EOT"
d /var/www 0755 apache apache -
d /var/log/httpd 0755 root root -
d /var/cache/httpd 0755 root root -
d /var/cache/httpd/proxy 0755 apache apache -
d /run/httpd 0755 root root -
z /usr/lib/httpd/suexec 4754 root apache -
EOT

    # "make install-httpd" from blfs-systemd-units. Not enabled.
    install -d "$DESTDIR/usr/lib/systemd/system"
    cat > "$DESTDIR/usr/lib/systemd/system/httpd.service" << "EOT"
[Unit]
Description=Apache Web Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/sbin/apachectl start
ExecStop=/usr/sbin/apachectl graceful-stop
ExecReload=/usr/sbin/apachectl graceful
PrivateTmp=true
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOT
}
