#!/usr/bin

set -e

function _download_source()
{
  LLVM_VERSION=$1

  echo "== [LLVM/Clang] Importing LLVM release key =="
  gpg --version &>/dev/null
  gpg --keyserver pool.sks-keyservers.net --recv-keys 0x8f0871f202119294

  for package in {llvm,cfe,clang-tools-extra,compiler-rt,libcxx,libcxxabi}; do
    echo "== [LLVM/Clang] Fetching ${package} ${LLVM_VERSION} source =="
    curl --progress-bar -O http://llvm.org/releases/${LLVM_VERSION}/${package}-${LLVM_VERSION}.src.tar.xz || exit 1
    echo "== [LLVM/Clang] Fetching ${package} ${LLVM_VERSION} signature =="
    curl --progress-bar -O http://llvm.org/releases/${LLVM_VERSION}/${package}-${LLVM_VERSION}.src.tar.xz.sig || exit 1

    echo "== [LLVM/Clang] Verifying signature of ${package} ${LLVM_VERSION} =="
    gpg ${package}-${LLVM_VERSION}.src.tar.xz.sig 2>&1 | grep "gpg: Good signature" || exit 1
  done
}

function _extract_source()
{
  LLVM_VERSION=$1

  echo "== [LLVM/Clang] Extracting source of llvm, ${LLVM_VERSION} =="
  mkdir llvm
  tar xf llvm-${LLVM_VERSION}.src.tar.xz -C llvm --strip-components 1

  echo "== [LLVM/Clang] Extracting source of clang, ${LLVM_VERSION} =="
  mkdir llvm/tools/clang
  tar xf cfe-${LLVM_VERSION}.src.tar.xz -C llvm/tools/clang --strip-components 1

  echo "== [LLVM/Clang] Extracting source of clang-tools-extra, ${LLVM_VERSION} =="
  mkdir llvm/tools/clang/tools/extra
  tar xf clang-tools-extra-${LLVM_VERSION}.src.tar.xz -C llvm/tools/clang/tools/extra --strip-components 1

  echo "== [LLVM/Clang] Extracting source of compiler-rt, ${LLVM_VERSION} =="
  mkdir llvm/projects/compiler-rt
  tar xf compiler-rt-${LLVM_VERSION}.src.tar.xz -C llvm/projects/compiler-rt --strip-components 1

  echo "== [LLVM/Clang] Extracting source of libcxx, ${LLVM_VERSION} =="
  mkdir llvm/projects/libcxx
  tar xf libcxx-${LLVM_VERSION}.src.tar.xz -C llvm/projects/libcxx --strip-components 1

  echo "== [LLVM/Clang] Extracting source of libcxxabi, ${LLVM_VERSION} =="
  mkdir llvm/projects/libcxxabi
  tar xf libcxxabi-${LLVM_VERSION}.src.tar.xz -C llvm/projects/libcxxabi --strip-components 1

  echo "== [LLVM/Clang] Cleaning up packages =="
  rm *.tar.xz
}

function _stage_one()
{
  echo "== [LLVM/Clang] Building stage 1 =="
  mkdir build
  cd build

  export CC=gcc
  export CXX=g++

  echo "== [LLVM/Clang] Configuring build =="
  cmake -G"Ninja" \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
    -DLIBCXX_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    ../llvm &>/dev/null

  echo "== [LLVM/Clang] Executing build =="
  cmake --build . --target install -- -j$(nproc)

  cd ..
  rm -rf build
}

function _stage_two()
{
  echo "== [LLVM/Clang] Building stage 2 =="

  mkdir build
  cd build

  export CC=clang
  export CXX=clang++

  echo "== [LLVM/Clang] Configuring build =="
  cmake -G"Ninja" \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_CXX_LINK_FLAGS="-lc++abi" \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
    -DLIBCXX_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LIBCXXABI=ON \
    -DLLVM_ENABLE_CXX1Y=ON \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_LIBCXXABI_INCLUDE_PATHS="../llvm/projects/libcxxabi/include" \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS="../llvm/projects/libcxxabi/include" \
    -DLIBCXX_CXX_ABI_LIBRARY_PATH="/usr/lib" \
    -DCPACK_GENERATOR=TGZ \
    ../llvm &>/dev/null

  echo "== [LLVM/Clang] Executing build =="
  cmake --build . --target install -- -j$(nproc)

  cd ..
  rm -rf build
}

cd /tmp

_download_source $1
_extract_source $1
_stage_one
_stage_two
