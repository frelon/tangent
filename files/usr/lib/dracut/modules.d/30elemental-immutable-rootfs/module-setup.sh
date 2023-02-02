#!/bin/bash

# called by dracut
check() {
    require_binaries "$systemdutildir"/systemd || return 1
    return 255
}

# called by dracut 
depends() {
    echo systemd rootfs-block dm fs-lib
    return 0
}

# called by dracut
installkernel() {
    instmods overlay
}

# called by dracut
install() {
    declare moddir=${moddir}
    declare systemdutildir=${systemdutildir}
    declare systemdsystemunitdir=${systemdsystemunitdir}

    inst_multiple \
        mount mountpoint sort rmdir findmnt rsync cut realpath basename lsblk

    inst_multiple -o \
        "$systemdutildir"/systemd-fsck partprobe sync udevadm parted mkfs.ext2 mkfs.ext3 mkfs.ext4 mkfs.vfat mkfs.fat mkfs.xfs blkid e2fsck resize2fs mount xfs_growfs umount sgdisk elemental
    inst_simple "${moddir}/elemental-immutable-rootfs.service" \
        "${systemdsystemunitdir}/elemental-immutable-rootfs.service"
    mkdir -p "${initdir}/${systemdsystemunitdir}/initrd-fs.target.requires"
    ln_r "../elemental-immutable-rootfs.service" \
        "${systemdsystemunitdir}/initrd-fs.target.requires/elemental-immutable-rootfs.service"
    ln_r "$systemdutildir"/systemd-fsck \
        "/sbin/systemd-fsck"
    dracut_need_initqueue
}
