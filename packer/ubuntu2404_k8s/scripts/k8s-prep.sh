#!/bin/bash
set -e

# Prevent interactive prompts during installation
export DEBIAN_FRONTEND=noninteractive

# Define versions
K8S_VERSION=v1.32
CRIO_VERSION=v1.34
LONGHORN_VERSION="v1.7.2" # Using 'v' prefix for GitHub API compatibility
CILIUM_CLI_VERSION=v0.19.2

echo ">>> Disabling Swap (Required for K8s)"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo ">>> Loading Kernel Modules for CRI-O, K8s, and Longhorn"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
iscsi_tcp
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe iscsi_tcp

echo ">>> Setting Sysctl params for Networking"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

echo ">>> Adding Repositories (CRI-O, K8s, and Helm)"
sudo apt-get update
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates gpg

# Create keyring directory
sudo mkdir -p -m 755 /etc/apt/keyrings

# 1. CRI-O Repository
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/cri-o.list

# 2. Kubernetes Repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

# 3. Helm Repository
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | \
    sudo gpg --dearmor -o /etc/apt/keyrings/helm.gpg
echo "deb [signed-by=/etc/apt/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

echo ">>> Installing Components"
sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl helm open-iscsi nfs-common jq grep sed
sudo apt-mark hold kubelet kubeadm kubectl cri-o

echo ">>> Starting and Enabling CRI-O & iSCSI (Required for Longhorn)"
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl enable iscsid --now

echo ">>> Installing Cilium CLI"

CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

echo ">>> Installing Longhorn CLI (lhctl)"
# Determine architecture for lhctl
LH_ARCH="amd64"
LHS_VERSION="v1.11.2"
if [ "$(uname -m)" = "aarch64" ]; then LH_ARCH="arm64"; fi

# Fetch the latest release version if not hardcoded
LH_RELEASE_TAG=$(curl -s https://api.github.com/repos/longhorn/cli/releases/latest | jq -r .tag_name)
echo "Downloading Longhorn CLI version ${LH_RELEASE_TAG}..."

curl -L "https://github.com/longhorn/cli/releases/download/${LHS_VERSION}/longhornctl-linux-${LH_ARCH}" -o longhornctl
sudo chmod +x longhornctl
sudo mv longhornctl /usr/local/bin/longhornctl
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc

echo ">>> Preparing Longhorn installation via Helm"
helm repo add longhorn https://charts.longhorn.io
helm repo update

echo ">>> Generating Unique iSCSI Initiator Name"
# Generate the name into a variable first to avoid read/write race conditions
NEW_INITIATOR_NAME=$(sudo iscsi-iname)

# Use sudo tee to write the file properly
echo "InitiatorName=${NEW_INITIATOR_NAME}" | sudo tee /etc/iscsi/initiatorname.iscsi

# Restart the service to pick up the new name
sudo systemctl restart iscsid

# Identify the second disk (scsi1 is usually /dev/sdb or /dev/vdb)
#DATA_DISK="/dev/sdb"

#echo ">>> Formatting Data Disk for Longhorn"
#sudo mkfs.xfs -f $DATA_DISK
#
#echo ">>> Creating Mount Point"
#sudo mkdir -p /var/lib/longhorn
#sudo mount $DATA_DISK /var/lib/longhorn

# Make it permanent
#echo "$DATA_DISK /var/lib/longhorn xfs defaults 0 0" | sudo tee -a /etc/fstab
#
#sudo systemctl disable --now multipathd || true

echo ">>> NOTE: Longhorn cluster components require 'kubeadm init' to be finished first."
echo ">>> After control plane is ready, run the following to install Longhorn:"
echo "    helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version ${LONGHORN_VERSION#v}"

echo ">>> Pre-flight check: Environment Readiness"
crio_status=$(systemctl is-active crio)
iscsid_status=$(systemctl is-active iscsid)
helm_version=$(helm version --short 2>/dev/null || echo "Not Found")
lhctl_version=$(lhctl version 2>/dev/null || echo "Installed at /usr/local/bin/lhctl")

echo "--- Summary ---"
echo "CRI-O is: $crio_status"
echo "iSCSI Service: $iscsid_status"
echo "Helm version: $helm_version"
echo "Longhorn CLI: $lhctl_version"
echo "--- Longhorn Deps Check ---"
if command -v iscsiadm >/dev/null && command -v mount.nfs >/dev/null; then
    echo "SUCCESS: Longhorn host dependencies (iscsi/nfs) are installed."
else
    echo "WARNING: Longhorn host dependencies might be missing."
fi

echo ">>> DONE. You can now run 'kubeadm init' on the control plane."