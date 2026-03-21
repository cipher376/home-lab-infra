variable "proxmox_api_url" {
  description = "The URL of the Proxmox API endpoint"
  type        = string
  default     = "https://172.16.0.15:8006/api2/json"
}

variable "proxmox_user" {
  description = "The Proxmox user to authenticate with"
  type        = string
}


variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  description = "Proxmox API token secret"
}

variable "proxmox_api_token_id" {
    type      = string
    sensitive = true

}

variable "ssh_public_key" {
    sensitive = true
    type      = string
}

