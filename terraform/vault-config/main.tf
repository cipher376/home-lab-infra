terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.51.1" # Or your preferred version
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
  
}

provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}


# 1. Enable the Kubernetes Auth Backend
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# 2. Configure it to talk to your K3s API
resource "vault_kubernetes_auth_backend_config" "k3s" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc"
  disable_iss_validation = "true" # Common for K3s/Ubuntu local certs
}

# 3. Create the KV-v2 Engine
resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV version 2 storage for GitLab and GPU tokens"
}



