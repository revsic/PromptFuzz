#!/bin/bash

source ../common.sh

PROJECT_NAME=libxml2-2-9-4
STALIB_NAME=libxml2.a
DYNLIB_NAME=libxml2.so
DIR=$(pwd)


function download() {
    cd $SRC
    git clone https://github.com/GNOME/libxml2
}

function build_lib() {
    # Build project
    LIB_STORE_DIR=$WORK/build
    rm -rf $LIB_STORE_DIR
    mkdir -p ${LIB_STORE_DIR}
    cd $LIB_STORE_DIR

    pushd $SRC/libxml2
    # vulnerable version
    git checkout v2.9.4

    extra_checks="integer,float-divide-by-zero"
    extra_cflags="-fsanitize=$extra_checks -fno-sanitize-recover=$extra_checks"
    export CFLAGS="$CFLAGS $extra_cflags"
    export CXXFLAGS="$CXXFLAGS $extra_cflags"

    CONFIG="--prefix=`realpath $LIB_STORE_DIR` --without-debug --without-http --without-python --with-zlib --with-lzma"
    ./autogen.sh --disable-shared  $CONFIG
    make -j$(nproc)
    make install

    ./autogen.sh $CONFIG
    make -j$(nproc)
    make install

    # copy the libraries
    cp  $LIB_STORE_DIR/lib/libxml2.a $LIB_STORE_DIR/libxml2.a
    cp `realpath $LIB_STORE_DIR/lib/libxml2.so` $LIB_STORE_DIR/libxml2.so

    popd
}

function build_oss_fuzz() {
    pwd
}

function copy_include() {
    cd ${LIB_BUILD}
    mkdir -p include/libxml
    cp $WORK/build/include/libxml2/libxml/*.h include/libxml
}

function build_corpus() {
    mkdir -p ${LIB_BUILD}/corpus
    cd $SRC/libxml2
    find test -type f -name "*.xml" | xargs -I {} cp {} ${LIB_BUILD}/corpus
}

function build_dict() {
    pwd
}

build_all
