#!/bin/sh

# Add current node in  /etc/hosts
echo "Adding current node in /etc/hosts"
echo "127.0.1.1 $(hostname)" >> /etc/hosts
echo "192.168.56.23 $(hostname)" >> /etc/hosts
echo "Adding master to hosts"
echo "192.168.56.22 calicomaster1" >> /etc/hosts

# Install prerequisite
echo "apt config"


apt-get update

apt-get install -y apt-transport-https ca-certificates curl net-tools bat bash-completion jq yq

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Preparing Helm install"

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

echo "Installing helm"

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# enable kernel modules
echo "enable reqired module kernel"
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# ufw rules
echo "Ufw config"
ufw allow "OpenSSH"
ufw allow 6443/tcp
ufw allow 2379:2380/tcp
ufw allow 10250/tcp
ufw allow 10259/tcp
ufw allow 10257/tcp
ufw allow 30000:32767/tcp
ufw enable

# systemctl parameters
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# disable swap
echo "Disabling swap"
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
free -m

# install containerd
echo "Installing containerd"

apt-get install -y containerd.io
systemctl stop containerd

mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# install kubeadm, kubelet and kubectl
echo "Installing kubeadm, kubelet and kubectl"
apt install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet  # enable kubelet service  
systemctl start kubelet   # start kubelet service

# update apparmor

echo "Updating apparmor"
apt install apparmor apparmor-utils -y

# install crictl
echo "Installing crictl"
CRICTL_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz

tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin

# install calico cli

echo "Initializing calicoctl on $(hostname)"

curl -L https://github.com/projectcalico/calico/releases/download/v3.30.2/calicoctl-linux-amd64 -o kubectl-calico
mv kubectl-calico /usr/local/bin/calicoctl
chmod +x /usr/local/bin/calicoctl 


# Configuring swap disabled at boot with grub
echo "Configuring swap disabled at boot with grub"

sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet systemd.swap=0"/g' /etc/default/grub

grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub

update-grub