# Not in the book: the newest stable upstream PyPI source release,
# built and installed as a wheel, without build isolation or dependency downloads.
# The wheel supplies vd, visidata, vdx, vd2to3.vdx, manual pages, desktop
# integration, and the in-application guides. standard-mailcap supplies the
# stdlib module removed in Python 3.13; curses and TOML come from Python.
# Packaged optional integrations: Excel xls/xlsx, HTML/XML, HTTP/ZIP-over-HTTP,
# YAML, NumPy, pandas/Stata, matplotlib SVG export, fonts, MessagePack/Brotli,
# web scraping, tabulate/Unicode width, process management and audio tags.
# tmux is vdx's default server launcher.
#
# Not included (their Python modules are not packaged): Arrow/Parquet/ORC/
# Feather (pyarrow), GeoParquet (shapely), HDF5 (h5py/PyTables), DuckDB (the
# duckdb package is the C library/CLI, not its Python module), ODS (odfpy),
# xls export (xlwt), binary xlsb (upstream's unversioned pyxlsb fork), SAS
# xpt/sas7bdat (xport/sas7bdat), SPSS (savReaderWriter's proprietary runtime),
# PostgreSQL (this loader needs psycopg2, not the packaged psycopg 3), MySQL
# (mysqlclient), S3/RDS (s3fs/boto3), shapefiles/vector tiles (pyshp/
# mapbox-vector-tile), PNG (pypng), PCAP (dpkt/dnslib), PDF (pdfminer.six/
# tabula), vCard (vobject), CoNLL (pyconll), FEC (fecfile), Frictionless
# (datapackage), graphviz export (namestand), zstd (zstandard), Seaborn,
# scraper cache (requests-cache), fake data (Faker), ping/vgit (sh), ptpython,
# Airtable/Matrix/Reddit/Zulip APIs and experimental cloud/LLM integrations.
# These loaders import dependencies only when used; no [all] extras or
# runtime pip installs are invoked by this recipe.

prepare() {
    # DataFrame.append was removed in pandas 2.0. Keep the pandas loader's
    # row insertion and undo bookkeeping working with joe's pandas 3.
    patch -Np1 -i /recipe/pandas-concat.patch
}

build() {
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
}

package() {
    pip3 install --no-index --no-deps --no-user --ignore-installed --no-warn-script-location \
        --prefix /usr --root "$DESTDIR" --find-links dist visidata
}
