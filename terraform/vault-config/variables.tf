variable "vault_addr" {
  type        = string
  description = "The network address of the Vault server"
  # Optional: You can set a default if Ansible doesn't provide one
 #  default     = "http://vault.vault.svc.cluster.local:8200"
}

# You likely need this one too for the provider to work!
variable "vault_token" {
  type        = string
  description = "The root or management token for Vault"
  sensitive   = true 
}