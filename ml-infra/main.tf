terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true
}

# 1. K3s Master (Control Plane) on the Dell venue
resource "proxmox_virtual_environment_vm" "k3s_master" {
  name        = "k3s-master-venue"
  node_name = "venue-node-03"
  vm_id      = 100
  clone {
    vm_id = 9000 # Your Ubuntu Template ID
    node_name = "prodesk-node-02" # The node where the template resides
    full  = true
  }
  cpu {
    cores = 2
    type = "x86-64-v2-AES" # Stable for 4th gen i5
  }
  memory { 
    dedicated = 4096 
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
      keys = [var.ssh_public_key]
    }
  }
  network_device {
    bridge = "vmbr0"
  }
  disk {
    datastore_id = "local-lvm"
    interface = "scsi0"
    size = 20
  }

}  

# 2. GUP Training Worker on the Legion
resource "proxmox_virtual_environment_vm" "ml_worker" {
  name = "ml-gpu-worker-legion"
  node_name = "legion-node-01"
  vm_id = 200

  cpu {
    cores = 12
    type = "host" #Crucial for AVX/ML performance
  }
  memory {
    dedicated =  24576 # 24GB RAM for large models
  }
  clone {
    vm_id = 9000
    node_name = "prodesk-node-02" # The node where the template resides
    full  = true
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
      keys = [var.ssh_public_key]
    }
  }

  # The NVIDIA Passthrough
  hostpci {
    device = "hostpci0"
    mapping = "Legion-GPU" # Use the name we defined in /etc/pve/mapping/pci.cfg
    rombar = true 
    pcie  = true
    xvga    = false # Avoid conflicts with Proxmox's VGA emulation, ensuring the GPU is fully dedicated to the VM for optimal performance.
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface = "scsi0"
    size = 500 # Larger disk for datasets and models
  }

}

#  3: GitLab & Model Registry (ProDesk)
resource "proxmox_virtual_environment_file" "gitlab_cloud_config" {
  node_name = "prodesk-node-02"
  content_type = "snippets"
  datastore_id = "local"
  source_raw {
    data = <<EOF
#cloud-config
runcmd:
  - fallocate -l 4G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo '/swapfile none swap sw 0 0' >> /etc/fstab
EOF
    file_name = "gitlab-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm"  "gitlab_server" {
  name = "gitlab-server"
  node_name = "prodesk-node-02"
  vm_id = 300

  initialization {
    datastore_id = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.gitlab_cloud_config.id
    ip_config {
      ipv4 {
        address = "172.16.0.102/24"
        gateway = "172.16.0.1"
      }
    }
    user_account {
      keys = [var.ssh_public_key]
    }
    
  }
  clone {
    vm_id = 9000
    node_name = "prodesk-node-02" # The node where the template resides
    full  = true
  }
  cpu {
    cores = 4
  }
  memory {
    dedicated = 8192 # 8GB RAM for GitLab
  }
  network_device {
    bridge = "vmbr0"
  }
  # Keep the OS on the 512GB NVMe
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 40 
  }

  # Put the Large Data/Models on the 8TB HDD
  disk {
    datastore_id = "HDD-8Tb"
    interface    = "scsi1"
    size         = 1000 # 1TB for the Model Registry
  }
}