# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="cryptodev-linux"
PKG_VERSION="bb8bc7cf60d2c0b097c8b3b0e807f805b577a53f"
PKG_SHA256="b97c87011ff5f91c90dfa94bedec3396eadd8374d9ecf49ce2951b479f83d5fe"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/cryptodev-linux"
PKG_URL="https://github.com/cryptodev-linux/cryptodev-linux/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="Cryptodev-linux driver"

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KERNEL_DIR="$(kernel_path)" \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    cp *.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}

  mkdir -p ${SYSROOT_PREFIX}/usr/include/crypto
    cp crypto/cryptodev.h ${SYSROOT_PREFIX}/usr/include/crypto
}
