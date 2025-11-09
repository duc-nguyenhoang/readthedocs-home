#!/bin/bash

set -e

IMAGE_DIR="/ssd/image"
DEVICE="/dev/sda"
BOOT_MOUNT="/ssd/tmp/sdboot"

echo "This will destroy all data on ${DEVICE}. Are you sure? (yes/[no])"
read confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Ensure all partitions on the device are unmounted
echo "[1/7] Unmounting all partitions on ${DEVICE}..."
sudo umount ${DEVICE}* || true

# Disable swap if it is active
echo "[2/7] Disabling swap..."
sudo swapoff -a || true

# Partition the SD card
echo "[3/7] Partitioning SD card..."
sudo sfdisk --force ${DEVICE} <<EOF
label: dos
label-id: 0xdeadbeef
device: ${DEVICE}
unit: sectors

${DEVICE}1 : start=2048, size=262144, type=83
${DEVICE}2 : size=2097152, type=83
${DEVICE}3 : size=262144, type=ef
${DEVICE}4 : type=83
EOF

# Format the partitions
echo "[4/7] Formatting partitions..."
sleep 2
sudo mkfs.ext4 -F ${DEVICE}1 -L vendor
sudo mkfs.ext4 -F ${DEVICE}2 -L system
sudo mkfs.vfat ${DEVICE}3
sudo mkfs.ext4 -F ${DEVICE}4 -L userdata

# Flash the vendor and system images
echo "[5/7] Flashing vendor and system images..."
sudo dd if=${IMAGE_DIR}/vendor.img of=${DEVICE}1 bs=1M status=progress
sudo dd if=${IMAGE_DIR}/system.img of=${DEVICE}2 bs=1M status=progress

# Mount the boot partition
echo "[6/7] Mounting boot partition..."
sudo mkdir -p ${BOOT_MOUNT}
sudo mount ${DEVICE}3 ${BOOT_MOUNT}

# Copy the boot files
echo "[7/7] Copying boot folder..."
sudo mkdir -p ${BOOT_MOUNT}/boot/extlinux
sudo mkdir -p ${BOOT_MOUNT}/boot/dtbs/starfive
sudo cp -v ${IMAGE_DIR}/jh7110-starfive-visionfive-2-v1.2a.dtb ${BOOT_MOUNT}/boot/dtbs/starfive
sudo cp -v ${IMAGE_DIR}/boot/extlinux/extlinux.conf ${BOOT_MOUNT}/boot/extlinux/
sudo cp -v ${IMAGE_DIR}/boot/uEnv.txt ${BOOT_MOUNT}/boot/
sudo cp -v ${IMAGE_DIR}/ramdisk.img ${BOOT_MOUNT}/
sudo mkdir -p ${BOOT_MOUNT}/dtbs/starfive
sudo cp -v ${IMAGE_DIR}/jh7110-starfive-visionfive-2-v1.2a.dtb ${BOOT_MOUNT}/dtbs/starfive/
sudo cp -v ${IMAGE_DIR}/Image.gz ${BOOT_MOUNT}/

# Sync and unmount
echo "[8/7] Syncing and unmounting..."
sync
sudo umount ${BOOT_MOUNT}
sudo rm -rf ${BOOT_MOUNT}

echo "[9/7] Done! SD card is ready."

