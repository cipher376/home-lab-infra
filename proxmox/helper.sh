# Pipes your local script directly into the remote bash process
ssh user@remote-node 'bash -s' < ./your-local-script.sh


#-----------------------------------------------------------------------------------------------
# 1. Send the file
scp ./my-tool.bin user@remote-node:/tmp/my-tool.bin

# 2. Execute and Delete in one go
ssh user@remote-node "chmod +x /tmp/my-tool.bin && /tmp/my-tool.bin; rm /tmp/my-tool.bin"



#-----------------------------Ansible ------------------------------------------------------------------
sudo dnf install -y ansible
ansible-vault create vars/secret.yml
ansible-playbook -i hosts.ini proxmox_bootstrap.yml --ask-vault-pass

# Create the file and add your vault password
echo "your_super_secret_vault_password" > .vault_pass
# CRITICAL: Set permissions so only YOU can read it
chmod 600 .vault_pass


export TF_VAR_proxmox_api_token_id="your-actual-token-id-here"
export TF_VAR_proxmox_api_token_secret="your-actual-token-uuid-here"


#-------------------------------------------------------------------------------------------------
#Purge kubernetes  On Master/Server Nodes
#bash# Stop and uninstall k3s server


#-------------------------------------------------------------------------------------------------
#Purge On Worker/Agent Nodes bash




# 1. Uninstall the Helm release
helm uninstall vault -n vault

# 2. Delete the namespace (this cleans up ServiceAccounts and Roles)
kubectl delete namespace vault

# 3. CRITICAL: Delete the persistent data (if using local-path or longhorn)
# This ensures the next install doesn't try to use the old, locked encrypted files
kubectl get pvc -n vault
kubectl delete pvc --all -n vault


kubectl -n vault  exec vault-0 -- /bin/sh -c  "VAULT_TOKEN='your-vault-root-token'  vault kv put secret/gitlab-runner/registration token='your-runner-gitlab-token'"


# 1. remove the files
rm /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml >> /dev/null

# 2. Restart the agent
systemctl restart  k3s-agent

# 3. Rund the config genrator 
nvidia-ctk runtime configure --runtime=containerd  --config=/var/lib/rancher/k3s/agent/etc/containerd/config.toml --set-as-default

systemctl stop  k3s-agent

# 4. verify the configuration 
cat /etc/containerd/conf.d/99-nvidia.toml  > /var/lib/rancher/k3s/agent/etc/containerd/config.toml
cat /etc/containerd/conf.d/99-nvidia.toml  > /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

echo "Restart the restart the agent to use the new configuration without regeneration."
systemctl start  k3s-agent

sleep 5
echo "Verify if the runtime was loaded"
crictl info | grep -i nvidia