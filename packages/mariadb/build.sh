# Following the book's MariaDB page, with the changes described below.

prepare() {
    # The book's patch: OpenSSL 4 rejects the way MariaDB initialises its
    # ciphers ("invalid iv length").
    patch -Np1 -i "$SOURCES/mariadb-12.3.3-openssl4_fixes-1.patch"

    # The account is the book's, mariadb, but upstream writes the name
    # mysql into its units and scripts (mariadbd-safe, galera_recovery,
    # the socket units) without a way to change it.
    sed -i -e 's/SET(MYSQLD_USER "mysql")/SET(MYSQLD_USER "mariadb")/' \
        -e 's/SET(MYSQLD_GROUP "mysql")/SET(MYSQLD_GROUP "mariadb")/' \
        support-files/CMakeLists.txt scripts/CMakeLists.txt
    sed -i -e 's/^User=mysql$/User=mariadb/' -e 's/^Group=mysql$/Group=mariadb/' \
        support-files/mariadb.service.in support-files/mariadb@.service.in
    grep -q '^User=mariadb$' support-files/mariadb.service.in
    grep -q '^User=mariadb$' support-files/mariadb@.service.in
    grep -q 'SET(MYSQLD_USER "mariadb")' scripts/CMakeLists.txt
}

build() {
    # The book's options, except:
    # - the data directory is /var/lib/mysql, not /srv/mariadb: /var is
    #   shared by every deployment, so rolling the system back never rolls
    #   a database back;
    # - no embedded server, unit tests, test suite (mariadb-test) or
    #   benchmark suite (sql-bench): the empty directories install neither;
    # - upstream's units are installed into the system unit directory, and
    #   the libraries MariaDB would otherwise build or download its own
    #   copy of are the system's: OpenSSL (not the bundled wolfSSL), zlib,
    #   PCRE2 and fmt.
    #
    # The client's line editing is MariaDB's bundled readline: upstream
    # does not link the system's readline 8, which is GPLv3, and libedit
    # has no recipe. System jemalloc, libaio and the snappy compression
    # provider are enabled. Still off: NUMA (numactl), io_uring, OQGraph
    # (Judy), Mroonga (it builds a bundled Groonga), MyRocks (a bundled
    # RocksDB), ColumnStore, the DuckDB engine (a second, bundled copy of
    # DuckDB) and the AWS key management plugin (the AWS SDK);
    # CONNECT's JDBC tables (they would tie the server to Java) and MongoDB
    # tables (mongo-c-driver). CONNECT keeps XML (libxml2) and ODBC
    # (unixODBC) tables.
    cmake -B build \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D INSTALL_DOCDIR=share/doc/mariadb-12.3.3 \
        -D INSTALL_DOCREADMEDIR=share/doc/mariadb-12.3.3 \
        -D INSTALL_MANDIR=share/man \
        -D INSTALL_MYSQLSHAREDIR=share/mariadb \
        -D INSTALL_MYSQLTESTDIR= \
        -D INSTALL_PAMDIR=lib/security \
        -D INSTALL_PAMDATADIR=/etc/security \
        -D INSTALL_PLUGINDIR=lib/mariadb/plugin \
        -D INSTALL_SBINDIR=sbin \
        -D INSTALL_SCRIPTDIR=bin \
        -D INSTALL_SQLBENCHDIR= \
        -D INSTALL_SUPPORTFILESDIR=share/mariadb \
        -D INSTALL_SYSTEMD_UNITDIR=/usr/lib/systemd/system \
        -D MYSQL_DATADIR=/var/lib/mysql \
        -D MYSQL_UNIX_ADDR=/run/mariadb/mariadb.sock \
        -D WITH_EXTRA_CHARSETS=complex \
        -D WITH_EMBEDDED_SERVER=OFF \
        -D WITH_UNIT_TESTS=OFF \
        -D WITH_SSL=system \
        -D WITH_ZLIB=system \
        -D WITH_PCRE=system \
        -D WITH_LIBFMT=system \
        -D WITH_READLINE=ON \
        -D WITH_SYSTEMD=yes \
        -D WITH_JEMALLOC=yes \
        -D WITH_NUMA=OFF \
        -D CMAKE_DISABLE_FIND_PACKAGE_URING=ON \
        -D CMAKE_REQUIRE_FIND_PACKAGE_LIBAIO=ON \
        -D PLUGIN_PROVIDER_SNAPPY=DYNAMIC \
        -D PLUGIN_OQGRAPH=NO \
        -D PLUGIN_MROONGA=NO \
        -D PLUGIN_ROCKSDB=NO \
        -D PLUGIN_COLUMNSTORE=NO \
        -D PLUGIN_DUCKDB=NO \
        -D PLUGIN_AWS_KEY_MANAGEMENT=NO \
        -D CONNECT_WITH_JDBC=OFF \
        -D CONNECT_WITH_MONGO=OFF
    make -C build
}

package() {
    make -C build DESTDIR="$DESTDIR" install

    # What upstream installs as its "Test" component even with no test
    # directory: mariadb-test, mariadb-client-test, the example and test
    # plugins and a PAM module for the test suite, with their manual pages
    # and their mysql* names ("TestSymlinks"). The two components are
    # installed on their own into a scratch directory, and every file in
    # it is removed from the package.
    local f
    install -d test-component
    for f in Test TestSymlinks; do
        DESTDIR="$PWD/test-component" cmake --install build --component "$f"
    done
    (cd test-component && find . ! -type d) | while IFS= read -r f; do
        rm -f "$DESTDIR/${f#./}"
    done
    (cd test-component && find . -mindepth 1 -depth -type d) | while IFS= read -r f; do
        rmdir "$DESTDIR/${f#./}" 2>/dev/null || true
    done

    # The static client library (libmariadbclient.a and its libmysqlclient
    # names); programs link libmariadb.so. libmysqlservices.a is kept: it
    # is the plugin service interface every server plugin is linked with.
    rm -f "$DESTDIR"/usr/lib/libmariadbclient.a "$DESTDIR"/usr/lib/libmariadb.a \
        "$DESTDIR"/usr/lib/libmysqlclient.a "$DESTDIR"/usr/lib/libmysqlclient_r.a

    # auth_pam_tool checks passwords through PAM for the auth_pam plugin,
    # which needs root to read /etc/shadow: upstream's packages make it
    # set-uid root in a directory only the server's account may enter.
    # Here the directory belongs to root, mode 0750, and is given the
    # mariadb group at boot (tmpfiles.d below).
    chmod 4755 "$DESTDIR/usr/lib/mariadb/plugin/auth_pam_tool_dir/auth_pam_tool"
    chmod 0750 "$DESTDIR/usr/lib/mariadb/plugin/auth_pam_tool_dir"

    # The book's /etc/my.cnf, with the data directory above.
    install -Dm644 /recipe/my.cnf "$DESTDIR/etc/my.cnf"

    # The account the book creates (groupadd -g 40, useradd -u 40), with
    # its home in the data directory; the data directory and the socket's
    # directory. No database is made: as root, run
    #   mariadb-install-db --user=mariadb --datadir=/var/lib/mysql
    # before starting mariadb.service.
    install -d "$DESTDIR/usr/lib/sysusers.d" "$DESTDIR/usr/lib/tmpfiles.d"
    cat > "$DESTDIR/usr/lib/sysusers.d/mariadb.conf" << "EOF"
g mariadb 40
u mariadb 40:40 "MariaDB Server" /var/lib/mysql /usr/bin/false
EOF
    cat > "$DESTDIR/usr/lib/tmpfiles.d/mariadb.conf" << "EOF"
d /var/lib/mysql 0700 mariadb mariadb -
d /run/mariadb 0755 mariadb mariadb -
z /usr/lib/mariadb/plugin/auth_pam_tool_dir 0750 root mariadb -
EOF

    # Upstream's units (mariadb.service, mariadb@.service, their sockets,
    # and the mysql/mysqld.service aliases) are installed by make install
    # into /usr/lib/systemd/system. None is enabled.
    test -f "$DESTDIR/usr/lib/systemd/system/mariadb.service"
}
