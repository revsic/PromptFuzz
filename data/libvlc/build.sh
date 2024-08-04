#!/bin/bash

source ../common.sh

PROJECT_NAME=libvlc
STALIB_NAME=libvlc.a
DYNLIB_NAME=libvlc.so
DIR=$(pwd)


function download() {
    cd $SRC
    wget https://download.videolan.org/pub/vlc/3.0.7.1/vlc-3.0.7.1.tar.xz
    tar xvf vlc-3.0.7.1.tar.xz
    mv vlc-3.0.7.1/ libvlc
}

function libfuzzer_env() {
    blue_echo "set libfuzzer env"
    export CC=clang
    export CXX=clang++

    unset CFLAGS
    unset CXXFLAGS
    # override for removing fuzzer-no-link(not been supported by gcc)
    FUZZER_FLAGS="-fno-omit-frame-pointer -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION $SANITIZER_FLAGS"
    export CFLAGS="${CFLAGS:-} $FUZZER_FLAGS"
    export CXXFLAGS="${CXXFLAGS:-} $FUZZER_FLAGS"
    export CUSTOM_FLAGS=${LIBFUZZER_CUSTOM_FLAGS:-}
    export LIB_FUZZING_ENGINE="-fsanitize=fuzzer"
}

function coverage_env() {
    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS
    blue_echo "set coverage env"
    export CC=clang
    export CXX=clang++
    # override for removing fuzzer-no-link(not been supported by gcc)
    COVERAGE_FLAGS="-g -fno-sanitize=undefined -fprofile-instr-generate -fcoverage-mapping -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION "
    export CFLAGS="${CFLAGS:-} $COVERAGE_FLAGS"
    export CXXFLAGS="${CXXFLAGS:-} $COVERAGE_FLAGS"
}

function build_lib() {
    # Build project
    LIB_STORE_DIR=$WORK/build
    rm -rf $LIB_STORE_DIR
    mkdir -p ${LIB_STORE_DIR}
    cd $LIB_STORE_DIR

    pushd $SRC/libvlc

    CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure --prefix=$LIB_STORE_DIR \
        --disable-lua --enable-static --enable-shared \
        --enable-coverage --with-sanitizer=address,undefined
    make libvlc -j$(nproc)
    make install
    cd lib && make install

    # copy the libraries
    cp -r $LIB_STORE_DIR/lib/* $LIB_STORE_DIR/

    popd
}

function build_oss_fuzz() {
    cd $SRC/libvlc/test
    make -j$(nproc) vlc-demux-libfuzzer CC=clang CFLAGS="-fsanitize=fuzzer"
    mv vlc-demux-libfuzzer $OUT
}

function copy_include() {
    cd ${LIB_BUILD}
    mkdir -p include/vlc
    cp -r $WORK/build/include/vlc/* include/vlc
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
