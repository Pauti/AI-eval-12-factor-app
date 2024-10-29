#!/bin/bash
sudo apt-get update && sudo apt-get install wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install nomad
sudo apt update && sudo apt install consul

# fix plugin error for working with consul
cd
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-arptables
echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-iptables

cd /etc/sysctl.d/ && sudo touch 10-bridge-nf-call-iptables.conf
echo "net.bridge.bridge-nf-call-arptables = 1" | sudo tee /etc/sysctl.d/10-bridge-nf-call-iptables.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.d/10-bridge-nf-call-iptables.conf
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.d/10-bridge-nf-call-iptables.conf
sudo sysctl --system