# Following the book's opencv page, with its FFmpeg 9 patch, without the
# contrib modules (opencv_contrib), and with these differences:
# - nothing is downloaded while configuring: IPP (ippicv, the archive the
#   book's note mentions) is off, and so is ADE, which the G-API module
#   needs, so opencv_gapi is not built;
# - no xine (xine-lib has no recipe) and no Jasper (likewise; JPEG 2000
#   goes through OpenJPEG);
# - the Python bindings are not built: they need NumPy, which has no
#   recipe yet. Nor are the Java bindings (they need Apache Ant);
# - JPEG XL (libjxl) and oneTBB, which joe has, are on;
# - every image library is the system one (BUILD_ZLIB/JPEG/PNG/TIFF/WEBP/
#   OPENJPEG/OPENEXR=OFF); protobuf (for the DNN module), flatbuffers and
#   ittnotify stay the copies in 3rdparty/, as upstream builds them by
#   default: the DNN importers are generated for its bundled protobuf.
# Switched off because what they need has no recipe or is not wanted:
# CUDA, OpenVINO, ONNX Runtime, VTK, GDAL, libdc1394, gPhoto2, LAPACK,
# Eigen (optional speed-ups; joe's Eigen is a 5.x release, and OpenCV's
# Eigen code is written for Eigen 3), VA-API interop, OpenGL windows (they
# need GTK 2's gtkglext or Qt), Halide, Vulkan (a DNN back end). OpenCL
# stays on: its headers are bundled and an OpenCL runtime is loaded only
# if one is installed. CPU_BASELINE and CPU_DISPATCH are upstream's x86-64
# defaults (SSE3 baseline, run-time dispatch to newer instruction sets).
prepare() {
    patch -Np1 -i "$SOURCES/opencv-4.13.0-ffmpeg-9.0.patch"
}

build() {
    mkdir build
    cd build
    cmake -D CMAKE_INSTALL_PREFIX=/usr \
        -D CMAKE_INSTALL_LIBDIR=lib \
        -D CMAKE_BUILD_TYPE=Release \
        -D ENABLE_CXX11=ON \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_DOCS=OFF \
        -D BUILD_opencv_apps=ON \
        -D BUILD_opencv_python2=OFF \
        -D BUILD_opencv_python3=OFF \
        -D BUILD_JAVA=OFF \
        -D BUILD_opencv_gapi=OFF \
        -D ENABLE_PRECOMPILED_HEADERS=OFF \
        -D ENABLE_CCACHE=OFF \
        -D CMAKE_SKIP_INSTALL_RPATH=ON \
        -D BUILD_WITH_DEBUG_INFO=OFF \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D OPENCV_ENABLE_NONFREE=OFF \
        -D BUILD_ZLIB=OFF \
        -D BUILD_JPEG=OFF \
        -D BUILD_PNG=OFF \
        -D BUILD_TIFF=OFF \
        -D BUILD_WEBP=OFF \
        -D BUILD_OPENJPEG=OFF \
        -D BUILD_OPENEXR=OFF \
        -D BUILD_JASPER=OFF \
        -D BUILD_TBB=OFF \
        -D BUILD_IPP_IW=OFF \
        -D BUILD_PROTOBUF=ON \
        -D PROTOBUF_UPDATE_FILES=OFF \
        -D WITH_IPP=OFF \
        -D WITH_ADE=OFF \
        -D WITH_FFMPEG=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_GTK=ON \
        -D WITH_GTK_2_X=OFF \
        -D WITH_QT=OFF \
        -D WITH_OPENGL=OFF \
        -D WITH_WAYLAND=OFF \
        -D WITH_V4L=ON \
        -D WITH_TBB=ON \
        -D WITH_JPEG=ON \
        -D WITH_PNG=ON \
        -D WITH_SPNG=OFF \
        -D WITH_TIFF=ON \
        -D WITH_WEBP=ON \
        -D WITH_OPENJPEG=ON \
        -D WITH_JASPER=OFF \
        -D WITH_OPENEXR=ON \
        -D WITH_AVIF=ON \
        -D WITH_JPEGXL=ON \
        -D WITH_XINE=OFF \
        -D WITH_1394=OFF \
        -D WITH_GPHOTO2=OFF \
        -D WITH_GDAL=OFF \
        -D WITH_GDCM=OFF \
        -D WITH_VTK=OFF \
        -D WITH_EIGEN=OFF \
        -D WITH_LAPACK=OFF \
        -D WITH_VA=OFF \
        -D WITH_VA_INTEL=OFF \
        -D WITH_CUDA=OFF \
        -D WITH_OPENVINO=OFF \
        -D WITH_ONNX=OFF \
        -D WITH_HALIDE=OFF \
        -D WITH_VULKAN=OFF \
        -D WITH_OPENCL=ON \
        -W no-author \
        -G Ninja ..
    ninja
}

package() {
    cd build
    DESTDIR="$DESTDIR" ninja install
}
