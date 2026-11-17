# Not in the book: the newest stable upstream PyPI source release,
# built and installed as a wheel, without build isolation or dependency downloads.
# Build and require Cython accelerators instead of silently dropping to
# Python if compilation fails. Cython 3.3 supports Python 3.15.
# SQLite is provided by Python, PostgreSQL by the packaged psycopg 3.
# Other DBAPI drivers and greenlet/asyncio extras are not included.

build() {
    REQUIRE_SQLALCHEMY_CEXT=1 pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --prefix /usr --root "$DESTDIR" --find-links dist sqlalchemy
}
