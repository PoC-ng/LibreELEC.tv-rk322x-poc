# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="dav1d"
PKG_VERSION="1.3.0"
PKG_SHA256="bde8db3d0583a4f3733bb5a4ac525556ffd03ab7dcd8a6e7c091bee28d9466b1"
PKG_LICENSE="BSD"
PKG_SITE="http://www.jbkempf.com/blog/post/2018/Introducing-dav1d"
PKG_URL="https://code.videolan.org/videolan/dav1d/-/archive/${PKG_VERSION}/dav1d-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="dav1d is an AV1 decoder :)"

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" nasm:host"
fi

PKG_MESON_OPTS_TARGET="-Denable_docs=false \
                       -Denable_examples=false \
                       -Denable_tests=false \
                       -Denable_tools=false \
                       -Dtestdata_tests=false"
