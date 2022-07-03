# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright The ignite Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"

  config.ssh.forward_agent = true
  config.vm.synced_folder "./", "/home/vagrant/", disabled: false, owner: "vagrant", group: "vagrant"

  for i in 60000..60100
    config.vm.network :forwarded_port, guest: i, host: i
  end
  cpus = 6
  memory = 8192
  config.vm.provider :virtualbox do |v, plus|
    # Enable nested virtualisation in VBox
    v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]

    v.cpus = cpus
    v.memory = memory
    plus.vm.synced_folder "./manifests", "/etc/firecracker/manifests", owner: "vagrant", group: "vagrant"
  end
  config.vm.provider :libvirt do |v, override|
    # If you want to use a different storage pool.
    # v.storage_pool_name = "vagrant"
    v.cpus = cpus
    v.memory = memory
    override.vm.synced_folder "./manifests", "/home/vagrant/", type: "nfs"
  end

  # modprobe overlay
  # modprobe br_netfilter
  
  # cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
  # overlay
  # br_netfilter
  # kvm-intel
  # vhost_vsock
  # EOF
  
  # cat <<EOF >  /etc/sysctl.d/ignite.conf
  # net.bridge.bridge-nf-call-ip6tables = 1
  # net.bridge.bridge-nf-call-iptables  = 0
  # net.ipv6.conf.all.disable_ipv6      = 1
  # net.ipv6.conf.default.disable_ipv6  = 1
  # net.ipv4.ip_forward                 = 1
  # EOF
  
  # sysctl --system

  config.vm.provision "upgrade-packages", type: "shell", run: "once" do |sh|
    sh.inline = <<~SHELL
      #!/usr/bin/env bash
      set -eux -o pipefail
      apt update && apt upgrade -y
    SHELL
  end

  config.vm.provision "install-basic-packages", type: "shell", run: "once" do |sh|
    sh.inline = <<~SHELL
      #!/usr/bin/env bash
      set -eux -o pipefail
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
    SHELL
  end

  config.vm.provision "install-docker", type: "shell", run: "once" do |sh|
    sh.inline = <<~SHELL
    curl -sSL https://get.docker.com/ | sh
    SHELL
  end

  config.vm.provision "install-cni", type: "shell", run: "once", privileged: true do |sh|
    sh.inline = <<~SHELL
      #!/usr/bin/env bash
      export CNI_VERSION=v0.9.1
      export ARCH=$([ $(uname -m) = "x86_64" ] && echo amd64 || echo arm64)
      mkdir -p /opt/cni/bin
      curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz | tar -xz -C /opt/cni/bin
      SHELL
  end

  config.vm.provision "file", source: "./config/config.yaml", destination: "/tmp/config.yaml"

  config.vm.provision "install-ignite", type: "shell", run: "once", privileged: true do |sh|
    sh.inline = <<~SHELL
      #!/usr/bin/env bash
      export VERSION=v0.10.0
      mkdir -p /etc/ignite
      cp /tmp/config.yaml /etc/ignite/config.yaml
      for binary in ignite ignited; do
        echo "Installing ${binary}..."
        curl -sfLo /tmp/${binary} https://github.com/weaveworks/ignite/releases/download/${VERSION}/${binary}-amd64
        chmod +x /tmp/${binary}
        mv /tmp/${binary} /usr/local/bin
        done
        SHELL
    end
end

# https://github.com/kubernetes/git-sync ?
