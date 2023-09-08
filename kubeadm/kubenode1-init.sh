#!/bin/bash

sudo lsmod | grep br_netfilter
sudo modprobe br_netfilter
sudo lsmod | grep br_netfilter
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

## INSTALLING DOCKER ENGINE BASED ON OS

yum --help &>> /dev/null
if [ $? -eq 0 ]
then
  # (Install Docker CE)
  ## Set up the repository
  ### Install required packages
  yum install -y yum-utils device-mapper-persistent-data lvm2
  ## Add the Docker repository
  yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  # Install Docker CE
  yum update -y && yum install -y \
    containerd.io-1.2.13 \
    docker-ce-19.03.11 \
    docker-ce-cli-19.03.11
  ## Create /etc/docker
  mkdir /etc/docker
  # Set up the Docker daemon
  cat > /etc/docker/daemon.json <<EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
  }
EOF
  mkdir -p /etc/systemd/system/docker.service.d
  # Restart Docker
  systemctl daemon-reload
  systemctl restart docker
  sudo systemctl enable docker
  
else
  # (Install Docker CE)
  ## Set up the repository:
  ### Install packages to allow apt to use a repository over HTTPS
  sudo apt-get update && sudo apt-get install -y \
    ca-certificates curl gnupg
  # Add Docker's official GPG key:
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  # Add the Docker apt repository:
  echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  # Install Docker CE
  sudo apt-get update && sudo apt-get install -y \
    containerd.io \
    docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) \
    docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)
  # Set up the Docker daemon
  sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2"
  }
EOF'
  sudo mkdir -p /etc/systemd/system/docker.service.d
  # Restart Docker
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo systemctl enable docker

fi

sleep 30

## Installing kubeadm, kubelet and kubectl 
yum --help &>> /dev/null
if [ $? -eq 0 ]
then
   cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
   [kubernetes]
   name=Kubernetes
   baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
   exclude=kubelet kubeadm kubectl
EOF
   
   # Set SELinux in permissive mode (effectively disabling it)
   sudo setenforce 0
   sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
   
   sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
   
   sudo systemctl enable --now kubelet
   systemctl stop firewalld
   systemctl disable firewalld
   
else
   
   sudo apt-get update && sudo apt-get install -y apt-transport-https curl
   sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
   deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
   sudo apt-get update
   sudo apt-get install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   sudo systemctl stop ufw
   sudo systemctl disable ufw
fi
sudo apt remove containerd
sudo apt update
sudo apt install containerd.io
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd
sleep 30
sudo chmod +x /vagrant/cltjoincommand.sh
sleep 180
sudo /vagrant/cltjoincommand.sh
