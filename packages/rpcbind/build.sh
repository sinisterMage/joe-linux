prepare() {
    # /etc/services (iana-etc) names port 111 sunrpc, not rpcbind.
    sed -i "/servname/s:rpcbind:sunrpc:" src/rpcbind.c
}

build() {
    # The unit directory is given so that upstream's rpcbind.service and
    # rpcbind.socket are installed. Neither is enabled.
    ./configure --prefix=/usr \
        --bindir=/usr/sbin \
        --enable-warmstarts \
        --with-rpcuser=rpc \
        --with-systemdsystemunitdir=/usr/lib/systemd/system
    make
}

package() {
    make DESTDIR="$DESTDIR" install

    # Read by rpcbind.service (EnvironmentFile).
    install -d "$DESTDIR/etc"
    echo 'RPCBIND_OPTIONS=""' > "$DESTDIR/etc/rpcbind.conf"

    # The account the book creates (groupadd -g 28, useradd -u 28). rpcbind
    # makes its warm-start directory, /run/rpcbind, itself.
    install -d "$DESTDIR/usr/lib/sysusers.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/rpcbind.conf" << "EOF"
g rpc 28
u rpc 28:28 "RPC Bind Daemon Owner" /dev/null /usr/bin/false
EOF
}
