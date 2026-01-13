#!/usr/bin/env bash
set -euf -o pipefail
set -x

# nix develop github:nixos/nixpkgs?rev=ffbc9f8cbaacfb331b6017d5a5abb21a492c9a38#linux_testing

if [[ ${DO_CLEAN_BUILD:-0} -eq 1 ]]; then
    MAKE_NIXOS_TARGET=clean-nixos-pkg
else
    MAKE_NIXOS_TARGET=dirty-nixos-pkg
fi

if [[ ${DO_CROSS_COMPILE:-0} -eq 1 ]]; then
    if [[ $(uname -m) == 'x86_64' ]]; then
        export ARCH=arm64
        export CROSS_COMPILE=aarch64-unknown-linux-gnu-
    elif [[ $(uname -m) == 'aarch64' ]]; then
        export ARCH=x86
        export CROSS_COMPILE=x86_64-linux-gnu-
    else
        echo 'Unsupported, bye'
        exit 1
    fi
fi

uname -a
make distclean
make defconfig
make $MAKE_NIXOS_TARGET
