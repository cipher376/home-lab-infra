#!/bin/bash

# Define the IDs we used
STORAGE_IDS=("Cluster-Templates" "Cluster-Models")
NODES=("172.16.0.10" "172.16.0.15" "172.16.0.20")

echo "--- Starting NFS Storage Purge ---"

# 1. Remove from Proxmox Cluster Config
for ID in "${STORAGE_IDS[@]}"; do
    echo "Removing $ID from Proxmox Datacenter..."
    # 2. Force Unmount on all nodes
    for NODE in "${NODES[@]}"; do
        echo "Cleaning up mounts on node $NODE..."
        ssh root@$NODE "pvesm remove $ID 2>/dev/null; \
                        umount -f /mnt/pve/Cluster-Templates 2>/dev/null; \
                        umount -f /mnt/pve/Cluster-Models 2>/dev/null; \
                        rm -rf /mnt/pve/Cluster-Templates; \
                        rm -rf /mnt/pve/Cluster-Models"
    done
done

echo "--- Cleanup Complete. Your cluster is ready for a fresh try. ---"