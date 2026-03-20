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

