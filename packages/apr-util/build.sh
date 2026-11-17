# Following the book's Apr-Util page.
build() {
    # The book's flags (crypto with OpenSSL, GDBM), plus the optional
    # dependencies that have recipes: the SQLite and ODBC database drivers
    # and LDAP, which Apache's mod_ldap and mod_authnz_ldap need. Each is a
    # module of its own in /usr/lib/apr-util-1. Off: the PostgreSQL and
    # MySQL drivers (those packages carry their servers, which apr-util and
    # Apache would then pull in), Berkeley DB and NDBM (no recipes), NSS and
    # the old SQLite 2.
    ./configure --prefix=/usr \
        --with-apr=/usr \
        --with-gdbm=/usr \
        --with-openssl=/usr \
        --with-crypto \
        --with-expat=/usr \
        --with-sqlite3=/usr \
        --with-odbc=/usr \
        --with-ldap \
        --without-pgsql \
        --without-mysql \
        --without-sqlite2 \
        --without-oracle \
        --without-berkeley-db \
        --without-ndbm \
        --without-nss
    make
}

package() {
    make DESTDIR="$DESTDIR" install
    # Static archives of the modules are not shipped.
    rm -f "$DESTDIR"/usr/lib/apr-util-1/*.a
}
