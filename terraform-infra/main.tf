terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true

  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}

locals {
  # Template IDs per node — assumed already present locally
  template_prodesk = 9000
  template_legion  = 9001
  template_venue   = 9002
  
}

# ------------------------------------------------------------------ #
#  VM 100 — K3s Master (venue-node-03)                                 #
# ------------------------------------------------------------------ #

resource "proxmox_virtual_environment_vm" "k3s_master" {
  name        = "k3s-master-venue"
  node_name   = "venue-node-03"
  vm_id       = 100
  description = "K3s control plane node"
  tags        = sort(["k3s", "master", "ubuntu","venue"])
  machine     = "q35"
  bios        = "ovmf"
  on_boot     = true
  started     = true

  clone {
    vm_id     = local.template_venue 
    node_name = "venue-node-03"
    full      = true
    retries   = 3
  }

  cpu {
    cores   = 3
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 6144
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 100
    file_format  = "raw"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "172.16.0.103/24"
        gateway = "172.16.0.1"
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      username = "ubuntu"
    }
  }

  lifecycle {
    ignore_changes = [
      disk,
      initialization,
      started,
    ]
  }
}

# ------------------------------------------------------------------ #
#  VM 101 — K3s Worker (prodesk-node-02)                                 #
# ------------------------------------------------------------------ #

resource "proxmox_virtual_environment_vm" "k3s_worker_prodesk" {
  name        = "k3s-worker-prodesk"
  node_name   = "prodesk-node-02"
  vm_id       = 101
  description = "K3s worker node"
  tags        = sort(["k3s", "worker", "ubuntu", "prodesk"])
  machine     = "q35"
  bios        = "ovmf"
  on_boot     = true
  started     = true

  clone {
    vm_id     = local.template_prodesk 
    node_name = "prodesk-node-02"
    full      = true
    retries   = 3
  }

  cpu {
    cores   = 4
    sockets = 1
    type    = "x86-64-v2-AES"
    units = 512
  }

  memory {
    dedicated = 6144
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 300
    file_format  = "raw"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "172.16.0.104/24"
        gateway = "172.16.0.1"
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      username = "ubuntu"
    }
  }

  lifecycle {
    ignore_changes = [
      disk,
      initialization,
      started,
    ]
  }
}

#------------------------------------------------------------------ #
# VM 200 — ML GPU Worker (legion-node-01)                             #
#------------------------------------------------------------------ #

resource "proxmox_virtual_environment_vm" "ml_worker" {
  name        = "ml-gpu-worker-legion"
  node_name   = "legion-node-01"
  vm_id       = 200
  description = "ML GPU worker with GTX 1660 Ti Mobile passthrough"
  tags        = sort(["ml", "gpu", "ubuntu"])
  machine     = "q35"
  bios        = "ovmf"
  on_boot     = true
  started     = true


  clone {
    vm_id     = local.template_legion
    node_name = "legion-node-01"
    full      = true
    retries   = 3
  }

  cpu {
    cores   = 12
    sockets = 1
    type    = "host"
    flags = [
      "+aes",
      "+pdpe1gb",
    ]
  }

  memory {
    dedicated = 26244
    floating  = 24576
  }

  hostpci {
    device  = "hostpci0"
    mapping = "Legion-GPU"
    rombar  = false
    pcie    = true
    xvga    = false
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"                     
    firewall = false
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 500
    file_format  = "raw"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "172.16.0.101/24"
        gateway = "172.16.0.1"
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      username = "ubuntu"
    }
  }

  lifecycle {
    ignore_changes = [
      disk,
      initialization,
      started,
    ]
  }
}

# ------------------------------------------------------------------ #
#  VM 300 — GitLab Server (prodesk-node-02)                            #
# ------------------------------------------------------------------ #

resource "proxmox_virtual_environment_file" "gitlab_cloud_config" {
  node_name    = "prodesk-node-02"
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    file_name = "gitlab-config.yaml"
    data      = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      hostname: gitlab-server
      fqdn: gitlab-server.local  
      manage_etc_hosts: true     
      runcmd:
        - fallocate -l 4G /swapfile
        - chmod 600 /swapfile
        - mkswap /swapfile
        - swapon /swapfile
        - echo '/swapfile none swap sw 0 0' >> /etc/fstab
      EOF
  }
}

resource "proxmox_virtual_environment_vm" "gitlab_server" {
  name        = "gitlab-server"
  node_name   = "prodesk-node-02"
  vm_id       = 300
  description = "GitLab server and model registry"
  tags        = sort(["gitlab", "ubuntu"])
  machine     = "q35"
  bios        = "ovmf"
  on_boot     = true
  started     = true


  clone {
    vm_id     = local.template_prodesk
    node_name = "prodesk-node-02"
    full      = true
    retries   = 3
  }

  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
    units = 1024
  }

  memory {
    dedicated = 8192
    floating  = 6144
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 40
    file_format  = "raw"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
  }

  disk {
    datastore_id = "Cluster-Models"
    interface    = "scsi1"
    size         = 1000
    file_format  = "raw"
    cache        = "none"
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.gitlab_cloud_config.id  # this line

    ip_config {
      ipv4 {
        address = "172.16.0.102/24"
        gateway = "172.16.0.1"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      disk,
      initialization,
      started,
    ]
  }
}





