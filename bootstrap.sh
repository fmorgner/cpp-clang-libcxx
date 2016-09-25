#!/bin/bash

set -e

function _exit()
{
  umount -R docker-void &>/dev/null
}

function _check_command()
{
  if ! hash $1; then
    echo "${1} was not found!"
    exit 1
  fi
}

function _check_environment()
{
  echo "== [BOOTSTRAP] Checking for required applications =="

  _check_command xbps-install
  _check_command arch-chroot

  if [[ -d docker-void && -z "${KEEP_OLD}" ]]; then
    echo "== [BOOTSTRAP] Removing leftovers from prior builds =="

    rm -rf docker-void
  fi
}

function _bootstrap_void()
{
  echo "== [BOOTSTRAP] Initializing Void Linux =="

  echo "Y" | \
  xbps-install --automatic \
    --yes \
    --rootdir=${PWD}/docker-void \
    --repository=http://repo.voidlinux.eu/current \
    --cachedir=${PWD}/.xbps-cache \
    --update \
    --sync \
    base-voidstrap \
    base-devel \
    curl \
    cmake \
    git \
    gnupg \
    ninja \
    python \
    python3.4 \
    python3.4-pip || true
}

function _bootstrap_conan
{
  echo "nameserver 8.8.8.8" >> docker-void/etc/resolv.conf

  echo "== [BOOTSTRAP] Installing Conan.io =="

  arch-chroot docker-void pip --no-cache-dir install conan 2>&1

  echo "== [BOOTSTRAP] Creating default Conan.io configuration =="

  mkdir -p docker-void/root/.conan
  cat >docker-void/root/.conan/conan.conf <<EOC
[storage]
path:~/.conan/data

[settings_defaults]
arch=x86_64
build_type=Release
compiler=clang
compiler.libcxx=libc++
compiler.version=${1}
os=$(uname -s)
EOC
}

function _build_clang()
{
  echo "== [BOOTSTRAP] Installing LLVM/Clang build script =="

  cp build_clang.sh docker-void/sbin/
  chown root:root docker-void/sbin/build_clang.sh

  echo "== [BOOTSTRAP] Building LLVM/Clang =="

  arch-chroot docker-void /bin/bash /sbin/build_clang.sh ${1} 2>&1
}

function _dockerize()
{
  echo "== [BOOTSTRAP] Cleaning target resolv.conf =="

  rm -f docker-void/etc/resolv.conf

  echo "== [BOOTSTRAP] Cleaning target bash history =="

  rm -f docker-void/root/.bash_history

  echo "== [BOOTSTRAP] Building docker image =="
  tar -pC docker-void -c . | docker import -c "ENV CC clang" -c "ENV CXX clang++" - fmorgner/cpp-clang-libcxx:${1}
}

LLVM_VERSION_FULL=$1
LLVM_VERSION_SHORT=$(echo ${LLVM_VERSION_FULL} | grep -oP '\d+\.\d+')

trap _exit EXIT

_check_environment
_bootstrap_void
_bootstrap_conan ${LLVM_VERSION_SHORT}
_build_clang ${LLVM_VERSION_FULL}
_dockerize ${LLVM_VERSION_SHORT}

echo "== [BOOTSTRAP] Finished =="
