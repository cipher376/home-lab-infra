#!/usr/bin/env bash
# =============================================================================
# setup-ansible-env.sh
# Bootstrap the Ansible virtual environment for home-lab-infra
# Requires Python 3.12 — community.hashi_vault does not load on Python 3.14
# Run from repo root: bash ansible/setup-ansible-env.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${REPO_ROOT}/ansible/.venv"
REQUIREMENTS_TXT="${REPO_ROOT}/ansible/requirements.txt"
REQUIREMENTS_YML="${REPO_ROOT}/ansible/requirements.yml"
COLLECTIONS_PATH="${VENV_DIR}/collections"

# Enforce Python 3.12 — 3.14 breaks community.hashi_vault module loading
if ! command -v python3.12 &>/dev/null; then
  echo "ERROR: python3.12 not found. Install it first:"
  echo "  sudo dnf install python3.12"
  exit 1
fi

echo "==> Python version: $(python3.12 --version)"

echo "==> Creating Python 3.12 venv at ${VENV_DIR}"
python3.12 -m venv "${VENV_DIR}" --clear

echo "==> Activating venv"
source "${VENV_DIR}/bin/activate"

echo "==> Upgrading pip"
pip install --upgrade pip --quiet

echo "==> Installing Python dependencies"
pip install -r "${REQUIREMENTS_TXT}"

echo "==> Installing Ansible collections into venv"
ansible-galaxy collection install \
  -r "${REQUIREMENTS_YML}" \
  -p "${COLLECTIONS_PATH}" \
  --force

echo "==> Patching ansible.cfg with venv collections path"
ANSIBLE_CFG="${REPO_ROOT}/ansible/ansible.cfg"
if grep -q "collections_path" "${ANSIBLE_CFG}" 2>/dev/null; then
  sed -i "s|collections_path.*|collections_path = ${COLLECTIONS_PATH}|" "${ANSIBLE_CFG}"
else
  sed -i '/^\[defaults\]/a collections_path = '"${COLLECTIONS_PATH}" "${ANSIBLE_CFG}"
fi

echo "==> Verifying vault_auth_method module"
MODULE_FILE="${COLLECTIONS_PATH}/ansible_collections/community/hashi_vault/plugins/modules/vault_auth_method.py"
if [[ -f "${MODULE_FILE}" ]]; then
  echo "    community.hashi_vault vault_auth_method: OK"
else
  echo "    ERROR: ${MODULE_FILE} not found"
  exit 1
fi

echo ""
echo "==> Done. Activate before running playbooks:"
echo ""
echo "    source ansible/.venv/bin/activate"
echo ""
echo "    ansible-playbook site.yaml \\"
echo "      -e \"@vars/secrets.yaml\" \\"
echo "      -e \"@hc-vault_keys.json\" \\"
echo "      --vault-password-file ./.vault_key"
echo ""
