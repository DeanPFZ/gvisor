#!/bin/bash

echo ">>> Installing gvisor (runsc) from source"

echo "

"
echo ">>> Installing Bazel to build gvisor"
sudo yum install zip zlib-devel unzip python java-1.8.0-openjdk gcc-c++
sudo yum groupinstall "Development Tools" #pkg-config download

echo "

"
echo ">>> Installing bazel to ~/bin"
sudo curl -O0RL https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo
sudo mv vbatts-bazel-epel-7.repo /etc/yum.repos.d/
sudo yum install bazel

echo "

"
echo ">>> Installing Docker"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce


echo "

"
echo ">>> Installing binutils"
sudo yum install binutils

echo "

"
echo ">>> Installing golang"
sudo yum install golang golang-src -y



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

if grep -q 'runsc' "/etc/docker/daemon.json"; then
	echo "Already Configured"
else

	sudo bash -c "echo '
{
    \"runtimes\": {
        \"runsc\": {
            \"path\": \"/usr/local/bin/runsc\"
        }
    }
}' >> /etc/docker/daemon.json"
fi

sudo systemctl restart docker
