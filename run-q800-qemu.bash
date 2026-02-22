#!/bin/bash
set -euo pipefail

machine_name="$1"

launch_dir="$PWD"

app_dir="${0%/*}"

#qemu_path=/btrfs/seagate4t/qemu/qemu-bin-9.1.1/bin/
#export PATH="${qemu_path}:$PATH"

display_type=gtk
[[ $(uname -s) = Darwin ]] && { display_type=cocoa; }

core_args=(
    -monitor stdio
    -M q800
    -m 136
    -bios "${app_dir}/Quadra800.rom"
    -display "$display_type" -g 1152x870x8
)

args=( "${core_args[@]}" )

function make_pram {
    #qemu-img create -f raw -o size=256b "${machine_name}.pram"
    dd if=/dev/zero of="${machine_name}.pram" bs=1 count=0 seek=256 2> /dev/null
}

function make_disk {
    #qemu-img create -f raw -o size=${1}M "${machine_name}.img"
    dd if=/dev/zero of="${machine_name}.img" bs=1 count=0 seek="$(( ${1} * 1024 * 1024 ))" 2> /dev/null
}

function attach_pram {
    args+=(
        -drive file="${1}",format=raw,if=mtd
    )
}

function attach_classicvirtio {
    # NB: this breaks booting with an empty PRAM
    args+=(
        -device nubus-virtio-mmio,romfile="${app_dir}/classicvirtio-drivers/classic/declrom"
        -device virtio-tablet-device
    )
}

function attach_network {
    # call with the netdev specification, eg:
    # attach_network user
    # attach_network vde,sock=/tmp/vde
    mac="08:00:07:$(md5sum <<<"${machine_name}" | perl -ne 'print join(":",(m/../g)[0,1,2])')"
    args+=(
        -nic "$1",model=dp8393x,mac=$mac
    )
}

scsi_index=0

function attach_disk {
    args+=(
        -device scsi-hd,scsi-id=${scsi_index},drive=xd${scsi_index}
        -drive file="${1}",media=disk,format=raw,if=none,id=xd${scsi_index}
    )
    scsi_index=$((++scsi_index))
}

function attach_cdrom {
    args+=(
        -device scsi-cd,scsi-id=${scsi_index},drive=xd${scsi_index}
        -drive file="${1}",media=cdrom,format=raw,if=none,id=xd${scsi_index}
    )
    scsi_index=$((++scsi_index))
}

virtioblk_index=0

function attach_virtioblk {
    args+=(
        -device virtio-blk,drive=vd${virtioblk_index}
        -blockdev driver=file,read-only=on,node-name=vd${virtioblk_index},filename="${1}"
    )
    virtioblk_index=$((++virtioblk_index))
}

p9p_index=0

function attach_9p {
    mac_name="$1"
    dir_path="$2"
    args+=(
        -device virtio-9p-device,fsdev=p9p${p9p_index},mount_tag="${mac_name}"
        -fsdev local,id=p9p${p9p_index},security_model=none,path="${dir_path}"
        # Use this option to boot from the device:
        #-device loader,addr=0x4400000,file="/PATH/TO/HOST/FOLDER/System Folder/Mac OS ROM"
    )
    p9p_index=$((++p9p_index))
}

function run {
    set -x
    qemu-system-m68k "${args[@]}" || true
    set +x
    echo
    stty sane
}

#attach_disk "${files_dir}/${machine_name}.img"
#attach_disk /tmp/aux/AUX3transfer.img
#attach_disk /tmp/aux/AUX3installboot.img

#scsi_index=3
#attach_cdrom nbd://ten64.local/Apple-Legacy-Nov_1999.iso
#attach_cdrom nbd://ten64.local/APPLE_AUX_3.1.0_FILE_SERVER_WGS95.ISO,throttling.iops-total=100
#attach_cdrom nbd://ten64.local/APPLE_AUX_3.1.0_DB_SERVER_WGS95.ISO
#attach_cdrom nbd://ten64.local/AppleShare_Pro_1.1_Install.iso
#attach_cdrom nbd://ten64.local/A-UX_Developer_Tools_1.1.iso
#attach_cdrom nbd://ten64.local/C_Object_Pascal_Workshop.toast
#attach_cdrom /btrfs/seagate4t/aux/macintoshgarden.org/sites/macintoshgarden.org/files/apps/MAC_OS_8-1_RETAIL.ISO
#attach_cdrom nbd://ten64.local/SYSTEM_7-5-3-RETAIL.ISO

#attach_virtioblk /btrfs/seagate4t/aux/macintoshgarden.org/sites/macintoshgarden.org/files/apps/StuffItExpander55.dsk
#attach_9p "9P" "/tmp/aux/shared/"

. "${machine_name}.conf"

run
