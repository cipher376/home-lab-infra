#Run on legion-node-01 to verify IOMMU is enabled, which is required for GPU passthrough. This is a prerequisite check before we attempt to create the GPU worker VM with Terraform.
# find your GPU's PCI address with lspci, then verify it shows up in the dmesg output as being assigned to an IOMMU group. If this check fails, GPU passthrough will not work and you may need to adjust your BIOS settings or kernel parameters.
lspci -nn | grep -i nvidia

# Edit the vfio.conf file to include your GPU's PCI IDs, which you can find from the lspci output. This tells the kernel to bind those devices to the VFIO driver for passthrough to VMs.
# eg. options vfio-pci ids=10de:2484,10de:228b disable_vga=1
nano /etc/modprobe.d/vfio.conf

#update initramfs to apply the new VFIO configuration
# 1. Ensure the module is loaded in the initramfs
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# 2. Rebuild the boot environment
update-initramfs -u -k all

# Reboot to apply changes and verify IOMMU groups again after reboot
lspci -nnk -s 0000:01:00.0
