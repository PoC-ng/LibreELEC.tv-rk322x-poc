# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="RTL8192FU"
PKG_VERSION="5153e7fdc905b5a73456ee312b8a0469ef816dab"
PKG_SHA256="ce52dd18dd6276bf4818f2a7ce315198a5db3326380017a9cb5192e94bf4d0d7"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/kelebek333/rtl8192fu-dkms/"
PKG_URL="https://github.com/kelebek333/rtl8192fu-dkms/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="Realtek RTL8192FU Linux driver"
PKG_IS_KERNEL_PKG="yes"

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX} \
       CONFIG_POWER_SAVING=n \
       USER_EXTRA_CFLAGS="-Wno-error=date-time"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    cp *.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
