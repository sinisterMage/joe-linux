build() {
    # The book's commands, without Python: --without-libraries=python
    # leaves out Boost.Python (and with it the NumPy bindings), so
    # bootstrap.sh does not look for an interpreter. MPI is not configured,
    # so Boost.MPI and Boost.Graph.Parallel are left out explicitly rather
    # than skipped with a warning. ICU is required rather than detected.
    # boost.stacktrace.backtrace=off: that variant needs libbacktrace, which
    # gcc does not install.
    ./bootstrap.sh --prefix=/usr \
        --with-icu \
        --without-libraries=python,mpi,graph_parallel
    ./b2 stage -j"$JOBS" threading=multi link=shared \
        boost.locale.icu=on \
        boost.stacktrace.backtrace=off
}

package() {
    # b2 knows no DESTDIR, so the prefix is moved into it. The installed
    # CMake package files find their directories relative to themselves,
    # but also record the install prefix; that is put back to /usr.
    # libboost_exception.a and libboost_test_exec_monitor.a exist only as
    # static libraries (see the book) and are kept, as the CMake files
    # refer to them.
    ./b2 install -j"$JOBS" threading=multi link=shared \
        boost.locale.icu=on \
        boost.stacktrace.backtrace=off \
        --prefix="$DESTDIR/usr"
    find "$DESTDIR/usr/lib/cmake" -name "*.cmake" -exec sed -i "s|$DESTDIR||g" {} +
}
