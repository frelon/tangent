#!/bin/bash

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

elemental_unit="elemental-immutable-rootfs.service"
elemental_layout="/run/cos/cos-layout.env" # TODO change to something under /run/elemental
root_part_mnt="/run/initramfs/cos-state" # TODO change to something under /run/elemental

# Omit any immutable roofs module logic if disabled
if getargbool 0 rd.elemental.disable; then
    exit 0
fi

# Omit any immutable rootfs module logic if no image path provided
elemental_img=$(getarg elemental-img/filename=)
[ -z "${elemental_img}" ] && exit 0

[ -z "${root}" ] && root=$(getarg root=)

root_perm="ro"
if getargbool 0 rd.elemental.debugrw; then
    root_perm="rw"
fi

oem_timeout=$(getargnum 120 1 1800 rd.elemental.oemtimeout=)
oem_label=$(getarg rd.elemental.oemlabel=)
elemental_overlay=$(getarg rd.elemental.overlay=)
[ -z "${elemental_overlay}" ] && elemental_overlay="tmpfs:20%"

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1
[ -d "$GENERATOR_DIR" ] || mkdir "$GENERATOR_DIR"

if [ -n "${oem_label}" ]; then
    dev=$(dev_unit_name /dev/disk/by-label/${oem_label})
    {
        echo "[Unit]"
        echo "DefaultDependencies=no"
        echo "Before=elemental-setup-rootfs.service"
        echo "Conflicts=initrd-switch-root.target"
        echo "[Mount]"
        echo "Where=/oem"
        echo "What=/dev/disk/by-label/${oem_label}"
        echo "Options=rw,suid,dev,exec,noauto,nouser,async"
    } > "$GENERATOR_DIR"/oem.mount

    if [ ! -e "$GENERATOR_DIR/elemental-setup-rootfs.service.wants/oem.mount" ]; then
        mkdir -p "$GENERATOR_DIR"/elemental-setup-rootfs.service.wants
        ln -s "$GENERATOR_DIR"/oem.mount \
            "$GENERATOR_DIR"/elemental-setup-rootfs.service.wants/oem.mount
    fi

    mkdir -p "$GENERATOR_DIR/$dev.device.d"
    {
        echo "[Unit]"
        echo "Before=initrd-root-fs.target"
        echo "JobRunningTimeoutSec=${oem_timeout}"
    } > "$GENERATOR_DIR/$dev.device.d/timeout.conf"

    if [ ! -e "$GENERATOR_DIR/initrd-root-fs.target.wants/$dev.device" ]; then
        mkdir -p "$GENERATOR_DIR"/initrd-root-fs.target.wants
        ln -s "$GENERATOR_DIR"/"$dev".device \
            "$GENERATOR_DIR"/initrd-root-fs.target.wants/"$dev".device
    fi
fi

case "${elemental_overlay}" in
    UUID=*) \
        elemental_overlay="block:/dev/disk/by-uuid/${elemental_overlay#UUID=}"
    ;;
    LABEL=*) \
        elemental_overlay="block:/dev/disk/by-label/${elemental_overlay#LABEL=}"
    ;;
esac

elemental_mounts=()
for mount in $(getargs rd.elemental.mount=); do
    case "${mount}" in
        UUID=*) \
            mount="/dev/disk/by-uuid/${mount#UUID=}"
        ;;
        LABEL=*) \
            mount="/dev/disk/by-label/${mount#LABEL=}"
        ;;
    esac
    elemental_mounts+=("${mount}")
done

mkdir -p "/run/systemd/system/${elemental_unit}.d"
{
    echo "[Service]"
    echo "Environment=\"elemental_mounts=${elemental_mounts[@]}\""
    echo "Environment=\"elemental_overlay=${elemental_overlay}\""
    echo "Environment=\"root_perm=${root_perm}\""
    echo "EnvironmentFile=${elemental_layout}"
} > "/run/systemd/system/${elemental_unit}.d/override.conf"

case "${root}" in
    LABEL=*) \
        root="${root//\//\\x2f}"
        root="/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    UUID=*) \
        root="/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    /dev/*) \
        rootok=1 ;;
esac

[ "${rootok}" != "1" ] && exit 0

dev=$(dev_unit_name "${root}")
root_part_unit="${root_part_mnt#/}"
root_part_unit="${root_part_unit//-/\\x2d}"
root_part_unit="${root_part_unit//\//-}.mount"

{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "DefaultDependencies=no"
    echo "After=dracut-initqueue.service"
    echo "Wants=dracut-initqueue.service"
    echo "[Mount]"
    echo "Where=${root_part_mnt}"
    echo "What=${root}"
    echo "Options=${root_perm},suid,dev,exec,auto,nouser,async"
} > "$GENERATOR_DIR/${root_part_unit}"

if [ ! -e "$GENERATOR_DIR/initrd-root-fs.target.requires/${root_part_unit}" ]; then
    mkdir -p "$GENERATOR_DIR"/initrd-root-fs.target.requires
    ln -s "$GENERATOR_DIR/${root_part_unit}" \
        "$GENERATOR_DIR/initrd-root-fs.target.requires/${root_part_unit}"
fi

mkdir -p "$GENERATOR_DIR/$dev.device.d"
{
    echo "[Unit]"
    echo "JobTimeoutSec=300"
    echo "JobRunningTimeoutSec=300"
} > "$GENERATOR_DIR/$dev.device.d/timeout.conf"

{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "DefaultDependencies=no"
    echo "RequiresMountsFor=${root_part_mnt}"
    echo "[Mount]"
    echo "Where=/sysroot"
    echo "What=${root_part_mnt}/${elemental_img#/}"
    echo "Options=${root_perm},suid,dev,exec,auto,nouser,async"
} > "$GENERATOR_DIR"/sysroot.mount

if [ ! -e "$GENERATOR_DIR/initrd-root-fs.target.requires/sysroot.mount" ]; then
    mkdir -p "$GENERATOR_DIR"/initrd-root-fs.target.requires
    ln -s "$GENERATOR_DIR"/sysroot.mount \
        "$GENERATOR_DIR"/initrd-root-fs.target.requires/sysroot.mount
fi

