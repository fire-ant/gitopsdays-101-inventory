#!/usr/bin/env bash
set -eux -o pipefail

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
kvm-intel
vhost_vsock
EOF

cat <<EOF | sudo tee /etc/sysctl.d/ignite.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 0
net.ipv6.conf.all.disable_ipv6      = 1
net.ipv6.conf.default.disable_ipv6  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# update and upgrade
apt update && apt upgrade -y
#  install pkgs
apt install -y --no-install-recommends \
make \
git \
gcc \
curl \
unzip \
dmsetup \
openssh-client \
binutils

# Install containerd if it's not present -- prevents breaking docker-ce installations
which containerd || apt-get install -y --no-install-recommends containerd

# probably better to run docker in a beefy microvm but necessary for other things
curl -sSL https://get.docker.com/ | sh

# install CNI
export CNI_VERSION=v0.9.1
export ARCH=$([ $(uname -m) = "x86_64" ] && echo amd64 || echo arm64)
mkdir -p /opt/cni/bin
curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz | tar -xz -C /opt/cni/bin

#  configure ignite
cat <<EOF | sudo tee /tmp/config.yaml
apiVersion: ignite.weave.works/v1alpha4
kind: Configuration
metadata:
  name: base-config
spec:
  runtime: containerd
  networkPlugin: cni
  vmDefaults:
    memory: 4GB
    diskSize: 10GB
    cpus: 4
    image:
      oci: chr1slavery/ignite-docker:20.04-amd64
    kernel:
      oci: weaveworks/ignite-kernel:5.14.16
    sandbox:
      oci: weaveworks/ignite:v0.10.0
EOF

#  install ignite
export VERSION=v0.10.0
mkdir -p /etc/ignite
cp /tmp/config.yaml /etc/ignite/config.yaml
for binary in ignite ignited; do
  echo "Installing ${binary}..."
  curl -sfLo /tmp/${binary} https://github.com/weaveworks/ignite/releases/download/${VERSION}/${binary}-amd64
  chmod +x /tmp/${binary}
  mv /tmp/${binary} /usr/local/bin
done

# https://github.com/kubernetes/git-sync
