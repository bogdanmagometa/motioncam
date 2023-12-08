#!/bin/bash
set -euxo pipefail

HALIDE_PATH="../../thirdparty/halide"

if [ ! -d ${HALIDE_PATH} ] 
then
    echo "Halide is missing. Run setupenv.sh first"
    exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	export DYLD_LIBRARY_PATH=${HALIDE_PATH}/lib
else
	export LD_LIBRARY_PATH=${HALIDE_PATH}/lib
fi

rm -rf tmp
mkdir -p tmp

g++ DenoiseGenerator.cpp ${HALIDE_PATH}/share/tools/GenGen.cpp -v -g -o3 -std=c++17 -I ${HALIDE_PATH}/include -L ${HALIDE_PATH}/lib -lHalide -lpthread -ldl -o ./tmp/denoise_generator
g++ PostProcessGenerator.cpp ${HALIDE_PATH}/share/tools/GenGen.cpp -v -g -o3 -std=c++17 -Wall -I ${HALIDE_PATH}/include -L ${HALIDE_PATH}/lib -lHalide -lpthread -ldl -o ./tmp/postprocess_generator
g++ CameraPreviewGenerator.cpp ${HALIDE_PATH}/share/tools/GenGen.cpp -v -g -o3 -std=c++17 -Wall -I ${HALIDE_PATH}/include -L ${HALIDE_PATH}/lib -lHalide -lpthread -ldl -o ./tmp/camera_preview_generator

function build_denoise() {
	TARGET=$1
	ARCH=$2
	FLAGS="no_runtime"

	echo "[$ARCH] Building forward_transform_generator"
	./tmp/denoise_generator -g forward_transform_generator -f forward_transform -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} input.type=uint16 levels=6

	echo "[$ARCH] Building fuse_image_generator"
	./tmp/denoise_generator -g fuse_image_generator -f fuse_image -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} input.type=uint16 reference.size=6 reference.type=float32 intermediate.size=6 intermediate.type=float32

	echo "[$ARCH] Building inverse_transform_generator"
	./tmp/denoise_generator -g inverse_transform_generator -f inverse_transform -e static_library,schedule,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} input.size=6
}

function build_postprocess() {
	TARGET=$1
	ARCH=$2
	FLAGS="no_runtime"

	echo "[$ARCH] Building measure_image_generator"
	./tmp/postprocess_generator -g measure_image_generator -f measure_image -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS}

	echo "[$ARCH] Building generate_edges_generator"
	./tmp/postprocess_generator -g generate_edges_generator -f generate_edges -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS}

	echo "[$ARCH] Building deinterleave_raw_generator"
	./tmp/postprocess_generator -g deinterleave_raw_generator -f deinterleave_raw -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS}

	echo "[$ARCH] Building postprocess_generator"
	./tmp/postprocess_generator -g postprocess_generator -f postprocess -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS}

	echo "[$ARCH] Building preview_generator2 rotation=0"
	./tmp/postprocess_generator -g preview_generator -f preview_landscape2 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=0 tonemap_levels=7 detail_radius=7 downscale_factor=2

	echo "[$ARCH] Building preview_generator2 rotation=90"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_portrait2 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=90 tonemap_levels=7 detail_radius=7 downscale_factor=2

	echo "[$ARCH] Building preview_generator2 rotation=-90"
	./tmp/postprocess_generator -g preview_generator -f preview_portrait2 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=-90 tonemap_levels=7 detail_radius=7 downscale_factor=2

	echo "[$ARCH] Building preview_generator2 rotation=180"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_landscape2 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=180 tonemap_levels=7 detail_radius=7 downscale_factor=2

	echo "[$ARCH] Building preview_generator4 rotation=0"
	./tmp/postprocess_generator -g preview_generator -f preview_landscape4 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=0 tonemap_levels=6 detail_radius=3 downscale_factor=4

	echo "[$ARCH] Building preview_generator4 rotation=90"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_portrait4 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=90 tonemap_levels=6 detail_radius=3 downscale_factor=4

	echo "[$ARCH] Building preview_generator4 rotation=-90"
	./tmp/postprocess_generator -g preview_generator -f preview_portrait4 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=-90 tonemap_levels=6 detail_radius=3 downscale_factor=4

	echo "[$ARCH] Building preview_generator4 rotation=180"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_landscape4 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=180 tonemap_levels=5 detail_radius=3 downscale_factor=4

	echo "[$ARCH] Building preview_generator8 rotation=0"
	./tmp/postprocess_generator -g preview_generator -f preview_landscape8 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=0 tonemap_levels=5 detail_radius=1 downscale_factor=8

	echo "[$ARCH] Building preview_generator8 rotation=90"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_portrait8 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=90 tonemap_levels=5 detail_radius=1 downscale_factor=8

	echo "[$ARCH] Building preview_generator8 rotation=-90"
	./tmp/postprocess_generator -g preview_generator -f preview_portrait8 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=-90 tonemap_levels=5 detail_radius=1 downscale_factor=8

	echo "[$ARCH] Building preview_generator8 rotation=180"
	./tmp/postprocess_generator -g preview_generator -f preview_reverse_landscape8 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} rotation=180 tonemap_levels=5 detail_radius=1 downscale_factor=8
}

function build_camera_preview() {
	TARGET=$1
	ARCH=$2
	FLAGS="no_runtime"

	echo "[$ARCH] Building camera_preview_generator2"
	./tmp/camera_preview_generator -g camera_preview_generator -f camera_preview2 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} tonemap_levels=7 downscaleFactor=2

	echo "[$ARCH] Building camera_preview_generator3"
	./tmp/camera_preview_generator -g camera_preview_generator -f camera_preview3 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} tonemap_levels=6 downscaleFactor=3

	echo "[$ARCH] Building camera_preview_generator4"
	./tmp/camera_preview_generator -g camera_preview_generator -f camera_preview4 -e static_library,h -o ../halide/${ARCH} target=${TARGET}-${FLAGS} tonemap_levels=6 downscaleFactor=4

	echo "[$ARCH] Building halide_runtime"
	./tmp/camera_preview_generator -r halide_runtime -e static_library,h -o ../halide/${ARCH} target=${TARGET}
}

mkdir -p ../halide/host

build_denoise host-profile host
build_postprocess host-profile host
build_camera_preview host-opencl-cl_half host

mkdir -p ../halide/arm64-v8a

build_denoise arm-64-android arm64-v8a
build_postprocess arm-64-android arm64-v8a
build_camera_preview arm-64-android-opencl-cl_half arm64-v8a
