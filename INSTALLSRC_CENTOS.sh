#!/bin/bash

# Prerequisites
# Git (sudo yum install git)

# Virtual Machine Needed!
# Using Vagrant..
# >> vagrant box add centos/7
# >> vagrant init centos/7
# >> vagrant up
# >> vagrant ssh

echo ">>> Installing gvisor (runsc) from source"

echo "

"
echo ">>> Installing Bazel to build gvisor"
sudo yum -y install zip zlib-devel unzip python java-1.8.0-openjdk gcc-c++
sudo yum -y groupinstall "Development Tools" #pkg-config download

echo "

"
echo ">>> Installing bazel to ~/bin"
sudo curl -O0RL https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo
sudo mv vbatts-bazel-epel-7.repo /etc/yum.repos.d/
sudo yum -y install bazel

echo "

"
echo ">>> Installing Docker"
# sudo yum remove -y docker docker-common docker-selinux docker-engine
sudo yum-config-manager --add-repo https://packages.docker.com/1.12/yum/repo/main/centos/7
sudo yum -y install docker-engine

echo "

"
echo ">>> Installing binutils"
sudo yum -y install binutils

echo "

"
echo ">>> Installing golang"
sudo yum -y install golang golang-src -y



echo ">>> Building runsc.."
sudo bazel clean --expunge
bazel build runsc

echo "

"
echo ">>> Copying build to /usr/local/bin"
sudo cp ./bazel-bin/runsc/linux_amd64_pure_stripped/runsc /usr/local/bin

echo "

"
echo ">>> Install of gvisor from source successful"
echo "

"

echo ">>> Configuring Docker to use runsc"

if [[ -f "/etc/docker/daemon.json" ]] && grep -q runsc "/etc/docker/daemon.json" 
then
	echo "Already Configured"
else

	sudo bash -c "echo '{
    \"runtimes\": {
        \"runsc\": {
            \"path\": \"/usr/local/bin/runsc\"
        }
    }
}' >> /etc/docker/daemon.json"
fi

sudo systemctl restart docker

# Need to disable SELinux by changing /etc/selinux/config to have SELINUX=disabled

# Need to install latest Linux version with following commands
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm 
sudo yum --enablerepo=elrepo-kernel install kernel-ml

# Change /etc/default/grub to GRUB_DEFAULT=0 - to enable newest linux version
# sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# REBOOT SYSTEM - then should be able to use gvisor environment
