#!/usr/bin/env bash

MASON_NAME=mapnik
MASON_VERSION=3.0.0
MASON_LIB_FILE=lib/libmapnik-wkt.a

. ${MASON_DIR}/mason.sh

function mason_load_source {
    mason_download \
        https://s3.amazonaws.com/mapnik/dist/v${MASON_VERSION}/mapnik-v${MASON_VERSION}.tar.bz2 \
        24699baf01fa24c09bee472d6e2b3a543326a161

    mason_extract_tar_bz2

    export MASON_BUILD_PATH=${MASON_ROOT}/.build/mapnik-v${MASON_VERSION}
}

function mason_compile {
    echo $(pwd)
    source bootstrap.sh
    if [[ $(uname -s) = 'Linux' ]]; then
        echo "CUSTOM_LDFLAGS = '-Wl,-z,origin -Wl,-rpath=\\\$\$ORIGIN'" >> config.py
    fi
    cat config.py
    ./configure PREFIX=${MASON_PREFIX} PYTHON_PREFIX=${MASON_PREFIX}
    cat ${MASON_BUILD_PATH}"/config.log"
    cat config.py
    echo $(pwd)
    JOBS=${MASON_CONCURRENCY} make
    make install
    if [[ `uname` = 'Darwin' ]]; then
        install_name_tool -id @loader_path/libmapnik.dylib ${MASON_PREFIX}"/lib/libmapnik.dylib";
        PLUGINDIRS=${MASON_PREFIX}"/lib/mapnik/input/*.input";
        for f in $PLUGINDIRS; do
            echo $f;
            echo `basename $f`;
            install_name_tool -id plugins/input/`basename $f` $f;
            install_name_tool -change ${MASON_PREFIX}"/lib/libmapnik.dylib" @loader_path/../../libmapnik.dylib $f;
        done;
    fi
    # push over GDAL_DATA, ICU_DATA, PROJ_LIB
    # fix mapnik-config entries for deps
    HERE=$(pwd)
    python -c "data=open('$MASON_PREFIX/bin/mapnik-config','r').read();open('$MASON_PREFIX/bin/mapnik-config','w').write(data.replace('$HERE','.'))"
    cat $MASON_PREFIX/bin/mapnik-config
    mkdir -p ${MASON_PREFIX}/share/icu
    cp -r $GDAL_DATA ${MASON_PREFIX}/share/
    cp -r $PROJ_LIB ${MASON_PREFIX}/share/
    cp -r $ICU_DATA/*dat ${MASON_PREFIX}/share/icu/
    find ${MASON_PREFIX} -name "*.pyc" -exec rm {} \;
}

function mason_cflags {
    ""
}

function mason_ldflags {
    ""
}

function mason_clean {
    make clean
}

mason_run "$@"
