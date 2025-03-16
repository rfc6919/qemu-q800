#!/bin/bash
set -euo pipefail

machine_name="$1"

files_dir="$PWD"
app_dir="${0%/*}"
cd "$app_dir"

qemu_path=/btrfs/seagate4t/qemu/qemu-bin-9.1.1/bin/
export PATH="${qemu_path}:$PATH"

core_args=(
    -monitor stdio
    -M q800
    -m 136
    -bios "${app_dir}/Quadra800.rom"
    -display gtk -g 1152x870x8
    -drive file="${files_dir}/${machine_name}.pram",format=raw,if=mtd
    -device nubus-virtio-mmio,romfile="${app_dir}/classicvirtio-drivers/classic/declrom"
    -device virtio-tablet-device
)

args=( "${core_args[@]}" )

function make_pram {
    qemu-img create -f raw -o size=256b "${machine_name}.pram"
}

function make_disk {
    qemu-img create -f raw -o size=${1}M "${machine_name}.img"
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

attach_disk "${files_dir}/${machine_name}.img"
#attach_disk /tmp/aux/AUX3transfer.img
#attach_disk /tmp/aux/AUX3installboot.img

scsi_index=3
#attach_cdrom nbd://ten64.local/Apple-Legacy-Nov_1999.iso
#attach_cdrom nbd://ten64.local/APPLE_AUX_3.1.0_FILE_SERVER_WGS95.ISO
#attach_cdrom nbd://ten64.local/APPLE_AUX_3.1.0_DB_SERVER_WGS95.ISO
#attach_cdrom nbd://ten64.local/AppleShare_Pro_1.1_Install.iso
#attach_cdrom nbd://ten64.local/A-UX_Developer_Tools_1.1.iso
#attach_cdrom nbd://ten64.local/C_Object_Pascal_Workshop.toast
#attach_cdrom /btrfs/seagate4t/aux/macintoshgarden.org/sites/macintoshgarden.org/files/apps/MAC_OS_8-1_RETAIL.ISO
#attach_cdrom nbd://ten64.local/SYSTEM_7-5-3-RETAIL.ISO

#attach_virtioblk /btrfs/seagate4t/aux/macintoshgarden.org/sites/macintoshgarden.org/files/apps/StuffItExpander55.dsk
attach_9p "9P" "/tmp/aux/shared/"

run
