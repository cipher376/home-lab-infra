terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }
}

provider "vault" {
  # Replace with your Venue node IP or internal K3s LoadBalancer DNS
  address = vars.vault_addr
  token   = vars.vault_token # Use the token from the Ansible logs
}


# Enable Kubernetes Auth Method
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# Configure the Auth Method to talk to your K8s API
resource "vault_kubernetes_auth_backend_config" "config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc" # Internal K8s DNS
  disable_iss_validation = true # Necessary for K8s 1.21+ to skip issuer checks
}

#------------------------------------------------------------#
#  INSTALL ARGOCD AND CONFIGURE TO USE CILIUM GATEWAY
#------------------------------------------------------------#
# 1. ArgoCD Helm Release with Gateway API Support
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  # Disable the default LoadBalancer since Cilium Gateway will handle the entry
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Ensure ArgoCD knows it is behind a TLS-terminating proxy
  set {
    name  = "server.extraArgs"
    value = "{--insecure}" # Gateway API handles TLS; ArgoCD stays plain HTTP internally
  }
}

resource "kubernetes_manifest" "argocd_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-route"
      namespace = "argocd"
    }
    spec = {
      parentRefs = [{
        name = "cilium-gateway"
      }]
      hostnames = ["argocd.lab.lan"]
      rules = [{
        backendRefs = [{
          name = "argocd-server"
          port = 80
        }]
      }]
    }
  }
}

# Define what ArgoCD is allowed to see
resource "vault_policy" "argocd_policy" {
  name   = "argocd-read-policy"
  policy = <<EOT
# Access to repository credentials and cluster tokens
path "secret/data/argocd/*" {
  capabilities = ["read"]
}

# Access to GPU-specific orchestration tokens if ArgoCD deploys them
path "secret/data/gpu-tokens/*" {
  capabilities = ["read"]
}
EOT
}

# Link the ArgoCD ServiceAccount to the Policy
resource "vault_kubernetes_auth_backend_role" "argocd_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "argocd-role"
  
  # ArgoCD's repo-server is usually what needs the secrets to render manifests
  bound_service_account_names      = ["argocd-repo-server"] 
  bound_service_account_namespaces = ["argocd"]
  
  token_policies                   = [vault_policy.argocd_policy.name]
  token_ttl                        = 3600
}


