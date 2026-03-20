#!/bin/bash
# Ensure any olde partitions are gone
wipefs -a -f /dev/sda

# Create the ZFS pool
zpool create -f -o ashift=12  HDD-8Tb /dev/sda

# verify the pool is created
zpool status HDD-8Tb

sleep 5

# Create a specific dataset for the models
zfs create HDD-8Tb/models

# Set recordsize to 1MB (optimized for large binary model files)
zfs set recordsize=1M HDD-8Tb/models

# Enable compression (ZFS compression is extremely fast and saves space)
zfs set compression=lz4 HDD-8Tb/models