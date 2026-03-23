variable "proxmox_api_url" {
  description = "The URL of the Proxmox API endpoint"
  type        = string
}

variable "proxmox_user" {
  description = "The Proxmox user to authenticate with"
  type        = string
}


variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "Proxmox API token secret"
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_user" {
  description = "SSH user for Proxmox nodes"
  type        = string
}

variable "proxmox_ssh_vm_user" {
  description = "SSH user for VMs"
  type        = string
}
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
variable "proxmox_ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
}

variable "proxmox_master_ip" {
  description = "IP address of the Proxmox host for SSH connections"
  type        = string
}