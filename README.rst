qemu-q800
=========

A crappy script to run a Quadra 800 VM in qemu.

How To
------

1. Clone this repo somewhere
2. For each VM you want, create a config file ``<vm_name>.conf``
3. The config file is a shell snippet sourced by the driver script ``run-q800-qemu.bash``, with a simple declaration of the VM config (see below).
4. Run the driver with the VM name as an argument. For a VM to be called ``aux31``, the config file is ``aux31.conf`` and you run it as ``./run-q800-qemu.bash aux31``.

Config
------

Config items are:

``make_pram``
    Ensure the PRAM file at ``<vm_name>.pram`` exists.

``make_disk <size_in_MB>``
    Ensure the raw disk image ``<vm_name>.img`` exists.

``attach_pram``
    Attach the PRAM file ``<vm_name>.pram`` to the VM.

``attach_classicvirtio``
    Attach a NuBus card to provide virtio support in Classic. This won't work under A/UX.

``attach_network <qemu_netdev>``
    Attach a dp8393x NIC to the VM. The simplest ``<qemu_netdev>`` is just ``user`` for usermode networking. If you have a more complex configuration, any normal qemu netdev spec will work (eg: ``attach_network vde,sock=/var/run/classic-lan``)

``attach_disk <disk_image_path>``
    Attach a raw hard drive image to the VM as a SCSI device. By default, the first SCSI device is given ID 0 with SCSI IDs increasing by 1 for each disk or cd. ``<disk_image_path>`` can just be a file name/path, or anything else that qemu accepts for a disk image path (like an ``nbd://`` url).

``attach_cdrom <cd_image_path>``
    Same as ``attach_disk``, except with ``media=cdrom`` instead of ``media=disk``.

``attach_virtioblk <virtioblk_image_path>``
    Same again, but attached as a virtioblk device rather than SCSI. Requires the classicvirtio NuBus device, and won't work under A/UX.

``attach_9p <mac_name> <directory_path>``
    Attach ``<directory_path>`` as a 9p filesystem named ``<mac_name>``. Requires the classicvirtio NuBus device, and won't work under A/UX.

Example config file
-------------------

    ::
    
        make_pram
        make_disk 1024
        
        attach_network user
        
        attach_disk aux.img
        #attach_cdrom Apple-Legacy-Nov_1999.iso # apple legacy recovery CD for A/UX installer
        #attach_cdrom APPLE_AUX_3.1.0_FILE_SERVER_AWS95.ISO # A/UX installation cd image

