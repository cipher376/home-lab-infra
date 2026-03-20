#!/bin/bash
# 1. Download Ubuntu 24.04 (Noble Numbat)
# Pro-tip: Download to /var/lib/vz/template/iso for persistence
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Optional: Install the agent into the disk image before template conversion
virt-customize -a noble-server-cloudimg-amd64.img --install qemu-guest-agent

sleep 5
# 2. Create the Template VM
qm create 9000 --name ubuntu-24-template --memory 2048 --net0 virtio,bridge=vmbr0 

# 3. Import to NVMe (local-lvm) instead of the HDD
# This makes cloning to other nodes MUCH faster
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm

# 4. Configure the VM
# Note: 'local-lvm' uses different naming syntax than ZFS
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit 
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0 

# 5. Important: Add the QEMU Guest Agent
# This allows Proxmox to see the VM's IP address (needed for Terraform)
qm set 9000 --agent enabled=1

# 6. Convert to Template
qm template 9000