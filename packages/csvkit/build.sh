# Not in the book: the newest stable upstream PyPI source release,
# built and installed as a wheel, without build isolation or dependency downloads.
# All 14 console scripts and their manual pages are installed by the wheel.
# SQLite and PostgreSQL (SQLAlchemy's psycopg driver) are available. Other
# database URLs need their unbundled SQLAlchemy driver; MySQL, Oracle, ODBC,
# and asynchronous drivers are not included. The optional zstandard Python
# module is not packaged; gzip/bzip2/xz inputs retain their stdlib support.

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --prefix /usr --root "$DESTDIR" --find-links dist csvkit
}
