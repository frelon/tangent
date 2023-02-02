#!/bin/bash
#
VM_NAME=${1:-tangent-0}
ISO_PATH=${2:-./tangent-x86_64.iso}

echo Deploying ${VM_NAME} using ${ISO_PATH}

virt-install --name $VM_NAME --vcpus=4  --memory 4096 --cpu host \
  --os-variant=sle15sp3 \
  --virt-type kvm \
  --boot loader=/usr/share/qemu/ovmf-x86_64-smm-suse-code.bin,loader.readonly=on,loader.secure=on,loader.type=pflash \
  --features smm.state=on \
  --disk path=/var/lib/libvirt/images/${VM_NAME}.img,bus=scsi,size=35,format=qcow2 \
  --check disk_size=off \
  --graphics none \
  --serial pty \
  --console pty,target_type=virtio \
  --rng random \
  --tpm emulator,model=tpm-crb,version=2.0 \
  --autostart \
  --cdrom $ISO_PATH  \
  --network bridge=vbr0
