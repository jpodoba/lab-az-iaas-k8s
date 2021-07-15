#!/bin/bash
FILE=k8s-install-ubuntu.log

if test -f "$FILE"; then
    echo "$FILE exists."
    exit
fi

if [ "$HOSTNAME" = "storage-vm" ]; then
    echo "Storage host\n" | tee -a $FILE
    
sudo apt-get install -y nfs-kernel-server | tee -a $FILE
sudo mkdir -p /export/volumes | tee -a $FILE
sudo mkdir -p /export/volumes/pod | tee -a $FILE

sudo bash -c 'echo "/export/volumes  *(rw,no_root_squash,no_subtree_check)" > /etc/exports' | tee -a $FILE
cat /etc/exports | tee -a $FILE
sudo systemctl restart nfs-kernel-server.service | tee -a $FILE
    
else
    echo "K8s host" | tee -a $FILE

swapoff -a | tee -a $FILE

sudo modprobe overlay | tee -a $FILE
sudo modprobe br_netfilter | tee -a $FILE

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system | tee -a $FILE

sudo apt-get update | tee -a $FILE
sudo apt-get install -y containerd | tee -a $FILE

sudo mkdir -p /etc/containerd | tee -a $FILE
sudo containerd config default | sudo tee /etc/containerd/config.toml | tee -a $FILE

sudo sed -i 's/.containerd.runtimes.runc.options]/.containerd.runtimes.runc.options]\n            SystemdCgroup = true/' /etc/containerd/config.toml | tee -a $FILE

sudo systemctl restart containerd | tee -a $FILE

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

sudo apt-get update | tee -a $FILE

VERSION=1.21.2-00
sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION | tee -a $FILE
sudo apt-mark hold kubelet kubeadm kubectl containerd | tee -a $FILE

sudo systemctl enable kubelet.service | tee -a $FILE
sudo systemctl enable containerd.service | tee -a $FILE

fi
