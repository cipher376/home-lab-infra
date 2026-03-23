#!/bin/bash
# nuke-and-pave.sh
set -e

PROXMOX_HOST="172.16.0.15"

echo "=========================================="
echo "  NUKE AND PAVE — Full Reset"
echo "=========================================="

echo ""
echo "Step 1: Destroying VMs on Proxmox..."
for vmid in 100 200 300; do
  echo "  -> VM $vmid"
  ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST "
    qm stop $vmid --skiplock 2>/dev/null || true
    qm unlock $vmid 2>/dev/null || true
    qm destroy $vmid --destroy-unreferenced-disks 1 --purge 1 2>/dev/null || true
  "# ------------------------------------------------------------------ #
#  STEP 1 — Destroy all VMs on Proxmox                                 #
# ------------------------------------------------------------------ #

# Stop and destroy all VMs
for vmid in 100 200 300; do
  echo "Destroying VM $vmid..."
  ssh root@172.16.0.15 "qm stop $vmid --skiplock 2>/dev/null || true"
  ssh root@172.16.0.15 "qm unlock $vmid 2>/dev/null || true"
  ssh root@172.16.0.15 "qm destroy $vmid --destroy-unreferenced-disks 1 --purge 1 2>/dev/null || true"
  echo "VM $vmid destroyed"
done

# Remove any orphaned conf files
ssh root@172.16.0.15 "rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/100.conf"
ssh root@172.16.0.15 "rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/200.conf"
ssh root@172.16.0.15 "rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/300.conf"
ssh root@172.16.0.15 "rm -f /etc/pve/nodes/legion-node-01/qemu-server/200.conf"
ssh root@172.16.0.15 "rm -f /etc/pve/nodes/venue-node-03/qemu-server/100.conf"

# Remove leftover disks
for vmid in 100 200 300; do
  echo "Cleaning leftover disks for VM $vmid..."
  ssh root@172.16.0.15 "
    for vol in \$(pvesm list local-lvm 2>/dev/null | grep 'vm-$vmid' | awk '{print \$1}'); do
      echo \"Removing \$vol\"
      pvesm free \"\$vol\" || true
    done
  "
done

# Verify all gone
ssh root@172.16.0.15 "pvecm status"
for vmid in 100 200 300; do
  ssh root@172.16.0.15 "qm status $vmid 2>&1 || echo VM $vmid is gone"
done

# ------------------------------------------------------------------ #
#  STEP 2 — Wipe Terraform state                                       #
# ------------------------------------------------------------------ #

# Destroy via Terraform first if state exists
terraform destroy -auto-approve || true

# Remove all state files
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# Remove Terraform cache
rm -rf .terraform/
rm -f .terraform.lock.hcl

# Verify state is clean
ls -la

# ------------------------------------------------------------------ #
#  STEP 3 — Reinitialize Terraform                                     #
# ------------------------------------------------------------------ #

terraform init

# Verify providers downloaded
terraform providers

# ------------------------------------------------------------------ #
#  STEP 4 — Validate config before applying                            #
# ------------------------------------------------------------------ #

terraform validate
terraform fmt

# Preview what will be created
terraform plan

# ------------------------------------------------------------------ #
#  STEP 5 — Apply                                                      #
# ------------------------------------------------------------------ #

terraform apply -auto-approve
done

echo ""
echo "Step 2: Removing orphaned conf files..."
ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST "
  rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/100.conf
  rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/200.conf
  rm -f /etc/pve/nodes/prodesk-node-02/qemu-server/300.conf
  rm -f /etc/pve/nodes/legion-node-01/qemu-server/200.conf
  rm -f /etc/pve/nodes/venue-node-03/qemu-server/100.conf
  echo 'Conf files cleaned'
"

echo ""
echo "Step 3: Cleaning leftover disks..."
ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST "
  for vmid in 100 200 300; do
    for vol in \$(pvesm list local-lvm 2>/dev/null | grep \"vm-\$vmid\" | awk '{print \$1}'); do
      echo \"Removing \$vol\"
      pvesm free \"\$vol\" || true
    done
    for vol in \$(pvesm list Cluster-Models 2>/dev/null | grep \"vm-\$vmid\" | awk '{print \$1}'); do
      echo \"Removing \$vol\"
      pvesm free \"\$vol\" || true
    done
  done
"

echo ""
echo "Step 4: Wiping Terraform state..."
terraform destroy -auto-approve 2>/dev/null || true
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
rm -rf .terraform/
rm -f .terraform.lock.hcl

echo ""
echo "Step 5: Reinitializing Terraform..."
terraform init

echo ""
echo "Step 6: Validating config..."
terraform validate

echo ""
echo "Step 7: Planning..."
terraform plan

echo ""
read -p "Proceed with apply? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
  echo "Step 8: Applying..."
  terraform apply -auto-approve
  echo ""
  echo "=========================================="
  echo "  Done! Infrastructure recreated."
  echo "=========================================="
else
  echo "Apply cancelled."
fi