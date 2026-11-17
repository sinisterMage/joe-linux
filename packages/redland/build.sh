# Following the book's redland page.
build() {
    # Storages: the built-in memory, file, hashes (in memory) and trees,
    # and SQLite. Left out: Berkeley DB (joe Linux does not package it), and
    # the MySQL, PostgreSQL, Virtuoso (ODBC) and 3store back ends, which
    # need a database server to be of any use. The installed libltdl is used
    # rather than the copy in the tarball.
    ./configure --prefix=/usr \
        --disable-static \
        --without-included-ltdl \
        --enable-storages="memory file hashes trees sqlite" \
        --with-sqlite=yes \
        --with-bdb=no \
        --with-mysql=no \
        --with-postgresql=no \
        --with-virtuoso=no \
        --with-threestore=no
    make
}

package() {
    make DESTDIR="$DESTDIR" install
}
