#!/bin/bash
#
# create_16mb_image.sh
#
# script to create flashable image for 16MB versions
#

# image read from old flash, possible to restore mtd0 and mtd4 from there
INPUT_IMAGE="flash32.bin"
#INPUT_IMAGE=""

# saved /dev/mtd0 and /dev(mtd4 partitions
MTD0_IMAGE="mtd0.bin"
MTD4_IMAGE="mtd4.bin"

# new uBoot from pepe2k
#
UBOOT_IMAGE="u-boot_mod__tp-link_tl-wr841n_v11__20170510__git_master-0c183583.bin"

# new Freifunk factory image for the TL-WR841N/ND V11 hardware
FIRMWARE_IMAGE="gluon-ffka-0.3.3-stable.0-20170423-tp-link-tl-wr841n-nd-v11-16mb.bin"

# resulting image file
OUTPUT_IMAGE="flash-16mb.bin"

# need first to check if all files are present
ALL_FILES="$UBOOT_IMAGE $FIRMWARE_IMAGE"
if [ "$INPUT_IMAGE" != "" ]; then
  ALL_FILES="$INPUT_IMAGE $ALL_FILES"
else
  ALL_FILES="$MTD0_IMAGE $MTD4_IMAGE $ALL_FILES"
fi

for file in $ALL_FILES; do
  echo "Checking for '$file' ..."
  if ! test -f $file; then
    echo "File '$file' doesn't exist, terminating!"
    exit 1
  fi
done

# create output image, might be empty
if [ "$INPUT_IMAGE" != "" ]; then
  echo "Creating 16 MByte flash image from 4 MByte image..."
  # old mtd0 and mtd4 partitions are already in place, uBoot needs to be replaced
  cat $INPUT_IMAGE $INPUT_IMAGE $INPUT_IMAGE $INPUT_IMAGE > $OUTPUT_IMAGE
else
  # 16 MBytes file containing zeros (aka. 256 * 64k)
  echo "Creating 16 MByte flash image..."
  #dd if=/dev/zero of=$OUTPUT_IMAGE bs=1M count=16
  dd if=/dev/zero ibs=64k count=256 | tr "\000" "\377" > $OUTPUT_IMAGE
  # place old mtd0 at the beginning
  echo "Copying MTD0 partition..."
  dd conv=notrunc if=$MTD0_IMAGE of=$OUTPUT_IMAGE
  # place old mtd4 at the end
  echo "Copying MTD4 partition..."
  dd conv=notrunc if=$MTD4_IMAGE of=$OUTPUT_IMAGE ibs=64k obs=64k seek=255
fi

# write new uBoot at the beginning, conserve config settings at the end
echo "Copying uBoot..."
dd conv=notrunc if=${UBOOT_IMAGE} of=$OUTPUT_IMAGE

# write the new firmware
echo "Copying the firmware..."
dd conv=notrunc if=${FIRMWARE_IMAGE} of=$OUTPUT_IMAGE ibs=64k obs=64k seek=2

# modify the magic byte (flash size)
echo "Setting magic byte..."
printf '\x16' | dd conv=notrunc of=$OUTPUT_IMAGE bs=1 seek=$((0x01fd02))

echo "Done!"

# eof
