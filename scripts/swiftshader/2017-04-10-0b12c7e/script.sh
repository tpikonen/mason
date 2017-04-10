#!/usr/bin/env bash

MASON_NAME=swiftshader
MASON_VERSION=2017-04-10-0b12c7e
MASON_LIB_FILE=lib/libGLESv2.${MASON_DYNLIB_SUFFIX}

. ${MASON_DIR}/mason.sh

function mason_load_source {
    export MASON_BUILD_PATH=${MASON_ROOT}/.build/swiftshader-${MASON_VERSION}
    if [ ! -d "${MASON_BUILD_PATH}" ]; then
        git clone --depth 1 --branch release https://github.com/mapbox/swiftshader.git "${MASON_BUILD_PATH}"
    fi
    git -C "${MASON_BUILD_PATH}" clean -fdxebuild
    git -C "${MASON_BUILD_PATH}" checkout 0b12c7e7c4e4bc8b51404226f4f572ad307b98c8
    git -C "${MASON_BUILD_PATH}" submodule update --init
}

function mason_compile {
    cmake -H. -Bbuild \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX="${MASON_PREFIX}" \
        -DBUILD_GLES_CM=NO \
        -DBUILD_SAMPLES=NO \
        -DREACTOR_BACKEND=LLVM
    make -C build libEGL libGLESv2

    rm -rf "${MASON_PREFIX}"
    mkdir -p "${MASON_PREFIX}/lib"
    cp -v "build/libEGL.${MASON_DYNLIB_SUFFIX}" "build/libGLESv2.${MASON_DYNLIB_SUFFIX}" "${MASON_PREFIX}/lib/"
    rsync -av "include" "${MASON_PREFIX}" --exclude Direct3D --exclude GL --exclude GLES
}

function mason_cflags {
    echo "-isystem ${MASON_PREFIX}/include"
}

function mason_ldflags {
    :
}

function mason_static_libs {
    :
}


if [ ${MASON_PLATFORM} = 'osx' ]; then
function mason_static_libs {
    echo "${MASON_PREFIX}/lib/libEGL.${MASON_DYNLIB_SUFFIX}"
    echo "${MASON_PREFIX}/lib/libGLESv2.${MASON_DYNLIB_SUFFIX}"
}
else
function mason_ldflags {
    echo "-L${MASON_PREFIX} -lEGL -lGLESv2"
}
fi

function mason_clean {
    make clean
}

mason_run "$@"