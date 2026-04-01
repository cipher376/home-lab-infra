# Home Lab Infrastructure

This repository contains the configuration and scripts for setting up and managing a home lab infrastructure. It includes Ansible playbooks, Terraform configurations, and Proxmox-related scripts to automate and streamline the deployment and management of the lab environment.

## Project Structure

### 1. Ansible Playbooks (`ansible-play-books/`)
This directory contains Ansible playbooks and related configuration files for automating infrastructure setup and management.

- **`ansible.cfg`**: Configuration file for Ansible.
- **`hosts.ini`**: Inventory file defining the hosts managed by Ansible.
- **`proxmox_bootstrap.yaml`**: Playbook for bootstrapping Proxmox.
- **`vars/secrets.yaml`**: Contains sensitive variables (ensure this file is secured).
- **`terraform.tfstate`**: Terraform state file used by Ansible.

### 2. Machine Learning Infrastructure (`ml-infra/`)
This directory contains Terraform configurations for setting up the machine learning infrastructure.

- **`main.tf`**: Main Terraform configuration file.
- **`variables.tf`**: Defines input variables for Terraform.
- **`terraform.tfvars`**: Contains values for the Terraform variables.
- **`terraform.tfstate`**: Terraform state file.
- **`terraform.tfstate.backup`**: Backup of the Terraform state file.

### 3. Proxmox Scripts (`proxmox/`)
This directory contains scripts for managing and configuring Proxmox.

- **`allow-legion-to-us-zfs-pool.sh`**: Script for managing ZFS pool permissions.
- **`create-zfs-pool.sh`**: Script for creating a ZFS pool.
- **`create_terraform_user_for_proxmox.sh`**: Script for creating a Terraform user in Proxmox.
- **`disable-enterprise-repostory.sh`**: Script to disable the enterprise repository.
- **`gpu-passthrough.sh`**: Script for GPU passthrough configuration.
- **`helper.sh`**: Helper script for various tasks.
- **`ubuntu-template.sh`**: Script for creating an Ubuntu template.

## Usage

### Prerequisites
- Ansible installed on your local machine.
- Terraform installed on your local machine.
- Access to a Proxmox environment.

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/cipher376/home-lab-infra.git
   ```
2. Navigate to the desired directory (e.g., `ansible-play-books/`, `ml-infra/`, or `proxmox/`).
3. Follow the instructions in the respective directory to execute the playbooks, Terraform configurations, or scripts.

## Notes
- Ensure sensitive files like `vars/secrets.yaml` are secured and not exposed.
- Backup your Terraform state files regularly.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or fixes.

# Commands:
ansible-playbook site.yaml -e "@ansible/vars/secrets.yaml" -e "@ansible/hc-vault_keys.json" --vault-password-file ./ansible/.vault_key 