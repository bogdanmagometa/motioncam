#!/bin/bash
set -euxo pipefail
# export ANDROID_NDK="$(brew --prefix)/share/android-ndk"
# export LLVM_DIR=/usr/local/Cellar/llvm/12.0.0/lib/cmake
if [[ -z "${ANDROID_NDK-}" ]]; then
	echo -e "Please set ANDROID_NDK to point to the NDK installation path"
	exit 1
fi

if [[ -z "${LLVM_DIR-}" ]]; then
	echo -e "Please set LLVM_DIR to point to LLVM"
	exit 1
fi

NUM_CORES="$(python3 -c 'import multiprocessing as mp; print(mp.cpu_count())')"

ANDROID_ABI="arm64-v8a"
OPENCV_VERSION="4.5.2"
LIBEXPAT_VERSION="2.2.10"
LIBEXIV2_VERSION="0.27.3"
ZSTD_VERSION="v1.4.9"
HALIDE_BRANCH=https://github.com/mirsadm/Halide

mkdir -p tmp
pushd tmp

build_opencv() {
	OPENCV_ARCHIVE="opencv-${OPENCV_VERSION}.zip"
	OPENCV_CONTRIB_ARCHIVE="opencv-contrib-${OPENCV_VERSION}.zip"

	curl -L https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip --output ${OPENCV_ARCHIVE}
	curl -L https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip --output ${OPENCV_CONTRIB_ARCHIVE}

	unzip ${OPENCV_ARCHIVE}
	unzip ${OPENCV_CONTRIB_ARCHIVE}

	pushd opencv-${OPENCV_VERSION}

	mkdir -p build
	pushd build

	cmake -DCMAKE_BUILD_TYPE=Release -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules -DCMAKE_INSTALL_PREFIX=../build/${ANDROID_ABI} -DCMAKE_SYSTEM_NAME=Android 	\
		-DANDROID_NATIVE_API_LEVEL=21 -DCMAKE_SYSTEM_VERSION=21 -DANDROID_ABI=${ANDROID_ABI} -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} -DANDROID_STL=c++_shared 								\
		-DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang -DWITH_TBB=ON -DBUILD_ANDROID_EXAMPLES=OFF -DBUILD_DOCS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_TESTS=OFF -DCPU_BASELINE=NEON 				\
		-DBUILD_JAVA=OFF -DENABLE_NEON=ON -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake ..

	make -j${NUM_CORES}

	make install

	INSTALL_DIR="../../../libMotionCam/thirdparty/opencv"

	mkdir -p ${INSTALL_DIR}/libs
	mkdir -p ${INSTALL_DIR}/include
	mkdir -p ${INSTALL_DIR}/thirdparty

	cp -a ./lib/. ${INSTALL_DIR}/libs/.
	cp -a ./${ANDROID_ABI}/sdk/native/jni/include/. ${INSTALL_DIR}/include/.
	cp -a ./${ANDROID_ABI}/sdk/native/3rdparty/. ${INSTALL_DIR}/thirdparty/.

	popd # build
	popd # opencv-${OPENCV_VERSION}

	touch ".opencv-${OPENCV_VERSION}"
}

build_expat() {
	LIBEXPAT_ARCHIVE="libexpat-${LIBEXPAT_VERSION}.tar.gz"

	curl -L https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-${LIBEXPAT_VERSION}.tar.gz --output ${LIBEXPAT_ARCHIVE}

	tar -xvf ${LIBEXPAT_ARCHIVE}

	pushd expat-${LIBEXPAT_VERSION}

	mkdir -p build
	pushd build

	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../build/${ANDROID_ABI} -DCMAKE_SYSTEM_NAME=Android 												\
		-DANDROID_NATIVE_API_LEVEL=21 -DCMAKE_SYSTEM_VERSION=21 -DANDROID_ABI=${ANDROID_ABI} -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} -DANDROID_STL=c++_shared 	\
		-DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_SHARED_LIBS=OFF 								\
		-DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake ..

	make -j${NUM_CORES}

	make install

	INSTALL_DIR="../../../libMotionCam/thirdparty/expat"

	mkdir -p ${INSTALL_DIR}/lib
	mkdir -p ${INSTALL_DIR}/include

	cp -a ./${ANDROID_ABI}/include/. ${INSTALL_DIR}/include/.
	cp -a ./${ANDROID_ABI}/lib/*.a ${INSTALL_DIR}/lib

	popd # build
	popd # expat-${LIBEXPAT_VERSION}

	touch ".expat-${LIBEXPAT_VERSION}"
}

build_exiv2() {
	LIBEXIV2_ARCHIVE="libexiv2-${LIBEXPAT_VERSION}.tar.gz"	

	curl -k -L https://github.com/Exiv2/exiv2/archive/refs/tags/v${LIBEXIV2_VERSION}.tar.gz --output ${LIBEXIV2_ARCHIVE}
#	curl -L https://www.exiv2.org/builds/exiv2-${LIBEXIV2_VERSION}-Source.tar.gz --output ${LIBEXIV2_ARCHIVE}

	tar -xvf ${LIBEXIV2_ARCHIVE}

	pushd exiv2-${LIBEXIV2_VERSION}
#	pushd exiv2-${LIBEXIV2_VERSION}-Source

	mkdir -p build
	pushd build

	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../build/${ANDROID_ABI} -DCMAKE_SYSTEM_NAME=Android 												\
		-DANDROID_NATIVE_API_LEVEL=21 -DCMAKE_SYSTEM_VERSION=21 -DANDROID_ABI=${ANDROID_ABI} -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} -DANDROID_STL=c++_shared 	\
		-DEXIV2_BUILD_SAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DEXIV2_BUILD_EXIV2_COMMAND=OFF																		\
		-DEXPAT_LIBRARY=../../../libMotionCam/thirdparty/expat/lib/libexpat.a -DEXPAT_INCLUDE_DIR=../../../libMotionCam/thirdparty/expat/include 				\
		-DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake ..

	make -j${NUM_CORES}

	make install

	INSTALL_DIR="../../../libMotionCam/thirdparty/exiv2"

	mkdir -p ${INSTALL_DIR}/lib
	mkdir -p ${INSTALL_DIR}/include

	cp -a ./${ANDROID_ABI}/include/. ${INSTALL_DIR}/include/.
	cp -a ./${ANDROID_ABI}/lib/*.a ${INSTALL_DIR}/lib/.

	popd # build
	popd # exiv2-${LIBEXIV2_VERSION}-Source

	touch ".exiv2-${LIBEXIV2_VERSION}"
}

build_zstd() {
	if [ ! -d "zstd-src" ]; then
		git clone https://github.com/facebook/zstd zstd-src
	fi

	pushd zstd-src

	git checkout ${ZSTD_VERSION}

	pushd build/cmake

	cmake  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../output/${ANDROID_ABI} -DCMAKE_SYSTEM_NAME=Android 												\
		-DANDROID_NATIVE_API_LEVEL=21 -DCMAKE_SYSTEM_VERSION=21 -DANDROID_ABI=${ANDROID_ABI} -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} -DANDROID_STL=c++_shared 	\
		-DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_TESTS=OFF -DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake .

	make -j${NUM_CORES}

	make install

	INSTALL_DIR="../../../../libMotionCam/thirdparty/zstd"

	mkdir -p ${INSTALL_DIR}/lib
	mkdir -p ${INSTALL_DIR}/include

	cp -a ../output/${ANDROID_ABI}/include/. ${INSTALL_DIR}/include/.
	cp -a ../output/${ANDROID_ABI}/lib/*.a ${INSTALL_DIR}/lib/.

	popd # /build/cmake
	popd # zstd-src

	touch ".zstd-${ZSTD_VERSION}"
}

build_halide() {
	if [ ! -d "halide-src" ]; then
		git clone ${HALIDE_BRANCH} halide-src
	fi

	pushd halide-src
#	git pull

	mkdir -p build
	pushd build

	INSTALL_DIR="../../../libMotionCam/thirdparty/halide"

	mkdir -p ${INSTALL_DIR}

	cmake -DTARGET_WEBASSEMBLY=OFF -DWITH_TUTORIALS=OFF -DWITH_TESTS=OFF -DWITH_PYTHON_BINDINGS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ..

	make -j${NUM_CORES}

	make install

	popd # build
	popd # halide-src

	touch ".halide"
}

# build_halide() {
# 	if [ ! -f "Halide-12.0.1-x86-64-osx-5dabcaa9effca1067f907f6c8ea212f3d2b1d99a.tar.gz" ]; then
# 		wget https://github.com/halide/Halide/releases/download/v12.0.1/Halide-12.0.1-x86-64-osx-5dabcaa9effca1067f907f6c8ea212f3d2b1d99a.tar.gz
# 	fi
# 	tar -xf Halide-12.0.1-x86-64-osx-5dabcaa9effca1067f907f6c8ea212f3d2b1d99a.tar.gz
	
# 	mv Halide-12.0.1-x86-64-osx halide
# 	cp -r halide ../libMotionCam/thirdparty/halide
# 	rm -rf halide

# 	touch ".halide"
# }

halide_generate() {
	pushd ../libMotionCam/libMotionCam/generators

	./generate.sh

	popd
}

# Build dependencies
if [ ! -f ".opencv-${OPENCV_VERSION}" ]; then
    build_opencv
fi

if [ ! -f ".expat-${LIBEXPAT_VERSION}" ]; then
	build_expat
fi

if [ ! -f ".exiv2-${LIBEXIV2_VERSION}" ]; then
	build_exiv2
fi

if [ ! -f ".zstd-${ZSTD_VERSION}" ]; then
	build_zstd
fi

if [ ! -f ".halide" ]; then
	build_halide
fi

# Generate halide libraries
halide_generate

popd # tmp
