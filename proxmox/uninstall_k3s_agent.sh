# Stop and uninstall k3s agent
kubectl delete crd $(kubectl get crds | grep 'gateway.networking.k8s.io' | awk '{print $1}')
sleep 5
sudo systemctl stop k3s-agent
sudo /usr/local/bin/k3s-agent-uninstall.sh

# If the uninstall script doesn't exist or fails, manual cleanup:
sudo systemctl stop k3s-agent
sudo systemctl disable k3s-agent
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /var/lib/kubelet
sudo rm -f /usr/local/bin/k3s*
sudo rm -f /usr/local/bin/kubectl
sudo rm -f /usr/local/bin/crictl
sudo rm -f /usr/local/bin/ctr
sudo rm -f /etc/systemd/system/k3s-agent.service
sudo rm -f /etc/systemd/system/k3s-agent.service.env
# Clean up CNI and networking
sudo rm -rf /etc/cni/net.d
sudo rm -rf /opt/cni/bin
sudo rm -rf /var/lib/cni

# Remove network interfaces (be careful with this!)
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete cilium_host 2>/dev/null || true
sudo ip link delete cilium_net 2>/dev/null || true
sudo ip link delete cilium_vxlan 2>/dev/null || true

# Clean iptables rules (optional, but thorough)
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Remove container images (optional)
sudo rm -rf /var/lib/rancher
# Reboot to ensure clean state (recommended)
sudo reboot