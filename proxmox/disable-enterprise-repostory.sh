#!/bin/bash

sed -i 's/^Enabled: yes/Enabled: no/' /etc/apt/sources.list.d/ceph.sources 2>/dev/null || sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/ceph.list

cat <<EOF > /etc/apt/sources.list.d/ceph-no-sub.sources
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

cat <<EOF > /etc/apt/sources.list.d/pve-no-sub.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF


apt update
