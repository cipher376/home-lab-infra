#!/bin/bash

#RUN ON LEGION SERVER

# 1. Install the server
apt install -y nfs-kernel-server

# 2. Grant permissions to the dataset folder
chown -R root:root /HDD-8Tb/models
chmod 777 /HDD-8Tb/models

# 3. Add to exports (Replace with your local network range)
echo "/HDD-8Tb/models 172.16.0.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

# 4. Refresh
exportfs -ra