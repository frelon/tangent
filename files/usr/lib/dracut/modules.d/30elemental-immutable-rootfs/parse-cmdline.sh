#!/bin/bash
# immutable root is specified with
# rd.elemental.mount=LABEL=<vol_label>:<mountpoint>
# rd.elemental.mount=UUID=<vol_uuid>:<mountpoint>
# rd.elemental.overlay=tmpfs:<size>
# rd.elemental.overlay=LABEL=<vol_label>
# rd.elemental.overlay=UUID=<vol_uuid>
# rd.elemental.oemtimeout=<seconds>
# rd.elemental.oemlabel=<vol_label>
# rd.elemental.debugrw
# rd.elemental.disable
# elemental-img/filename=/cOS/active.img

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 rd.elemental.disable; then
    return 0
fi

elemental_img=$(getarg elemental-img/filename=)
[ -z "${elemental_img}" ] && return 0
[ -z "${root}" ] && root=$(getarg root=)

root_perm="ro"
if getargbool 0 rd.elemental.debugrw; then
    root_perm="rw"
fi

case "${root}" in
    LABEL=*) \
        root="${root//\//\\x2f}"
        root="/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    UUID=*) \
        root="/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    /dev/*) \
        root="${root}"
        rootok=1 ;;
esac

[ "${rootok}" != "1" ] && return 0

info "root device set to root=${root}"

wait_for_dev -n "${root}"

# set sentinel file for boot mode
mkdir -p /run/elemental
case "${elemental_img}" in
    *recovery*)
        echo -n 1 > /run/elemental/recovery_mode ;;
    *active*)
        echo -n 1 > /run/elemental/active_mode ;;
    *passive*)
        echo -n 1 > /run/elemental/passive_mode ;;
esac

return 0

