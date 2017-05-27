#!/bin/bash
#
# modify_uboot.sh
#
# Script to create modified uBoot from backup of /dev/mtd0 and other ingredients
# for the TP-Link TL-WR841N/ND v11
#

MTD0_IMAGE="mtd0.bin"
# see also:
#  https://github.com/pepe2k/u-boot_mod
#  http://projects.dymacz.pl/?dir=u-boot_mod
#UBOOT_IMAGE="u-boot_mod__tp-link_tl-wr841n_v11__20170413__git_master-7e7a2ab4.bin"
#UBOOT_IMAGE="u-boot_mod__tp-link_tl-wr841n_v11__20170425__git_master-aba8e6f8.bin"
UBOOT_IMAGE="u-boot_mod__tp-link_tl-wr841n_v11__20170510__git_master-0c183583.bin"

# check if everything is in place
if ! test -f ${MTD0_IMAGE}; then
  echo "Image of MTD0 '${MTD0_IMAGE}' is not existing!"
  exit 1
fi

if ! test -f ${UBOOT_IMAGE}; then
  echo "uBoot image '${UBOOT_IMAGE}' is not existing!"
  exit 1
fi

MTD0_NEW_IMAGE=$(basename ${MTD0_IMAGE})
MTD0_NEW_IMAGE=${MTD0_NEW_IMAGE%%.*}-merged.bin

echo -n "Merging ${MTD0_IMAGE} "
echo "with ${UBOOT_IMAGE} into ${MTD0_NEW_IMAGE} ..."

# copy the old image, i.e. leave it untouched as backup
dd if=${MTD0_IMAGE} of=${MTD0_NEW_IMAGE}

# copy the uBoot (shorter) OVER the MTD0 image, thus keeping the bytes at the end
dd conv=notrunc if=${UBOOT_IMAGE} of=${MTD0_NEW_IMAGE}

# write the new flash size to a specific place into the resulting image, here 8 MByte
#printf '\x08' | dd conv=notrunc of=${MTD0_NEW_IMAGE} bs=1 seek=$((0x01fd02))
# and for 16 MBytes, content is interpreted string-like thus 0x16 and not 0x10
printf '\x16' | dd conv=notrunc of=${MTD0_NEW_IMAGE} bs=1 seek=$((0x01fd02))

# eof

