#!/bin/bash

source ../common.sh

PROJECT_NAME=libvlc
STALIB_NAME=libvlc.la
DYNLIB_NAME=libvlc.so
DIR=$(pwd)


function download() {
    cd $SRC
    wget https://download.videolan.org/pub/vlc/3.0.7.1/vlc-3.0.7.1.tar.xz
    tar xvf vlc-3.0.7.1.tar.xz
    mv vlc-3.0.7.1/ libvlc
}

function build_lib() {
    # Build project
    LIB_STORE_DIR=$WORK/build
    rm -rf $LIB_STORE_DIR
    mkdir -p ${LIB_STORE_DIR}
    cd $LIB_STORE_DIR

    pushd $SRC/libvlc

    # ./configure --prefix=$LIB_STORE_DIR --disable-lua
    # make -j$(nproc)

    FLAGS="-fno-omit-frame-pointer -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -O2 -fsanitize-address-use-after-scope"

    CC=afl-clang-lto CXX=afl-clang-lto++ CFLAGS=$FLAGS CXXFLAGS=$FLAGS \
        ./configure --disable-lua
    AFL_USE_ASAN=1 AFL_USE_UBSAN=1 make -j8 libvlc
    make install

    # copy the libraries
    cp -r $LIB_STORE_DIR/lib/* $LIB_STORE_DIR/

    popd
}

function build_oss_fuzz() {
    cd $SRC/libvlc/test
    make -j$(nproc) vlc-demux-libfuzzer
    mv vlc-demux-libfuzzer $OUT
}

function copy_include() {
    cd ${LIB_BUILD}
    mkdir -p include/vlc
    cp $WORK/build/include/vlc/* include/vlc
}

function build_corpus() {
    mkdir -p ${LIB_BUILD}/corpus
    cd $SRC/libvlc
    find test -type f -name "*.mp3" | xargs -I {} cp {} ${LIB_BUILD}/corpus
    find test -type f -name "*.mp4" | xargs -I {} cp {} ${LIB_BUILD}/corpus
    find test -type f -name "*.srt" | xargs -I {} cp {} ${LIB_BUILD}/corpus
    find test -type f -name "*.aac" | xargs -I {} cp {} ${LIB_BUILD}/corpus
    find test -type f -name "*.mkv" | xargs -I {} cp {} ${LIB_BUILD}/corpus
    find test -type f -name "*.voc" | xargs -I {} cp {} ${LIB_BUILD}/corpus
}

function build_dict() {
    pwd
}

build_all
