#!/bin/bash

echo ">>> Installing gvisor (runsc) from source"

echo "

"
echo ">>> Installing Bazel to build gvisor"
sudo apt-get install pkg-config zip g++ zlib1g-dev unzip python

echo "

"
echo ">>> Getting bazel installer binary"
curl -O0RL https://github.com/bazelbuild/bazel/releases/download/0.16.1/bazel-0.16.1-installer-linux-x86_64.sh

echo "

"
echo ">>> Installing bazel to ~/bin"
chmod +x bazel-0.16.1-installer-linux-x86_64.sh
./bazel-0.16.1-installer-linux-x86_64.sh

echo "

"
echo ">>> Installing Docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

echo "

"
echo ">>> Installing binutils-gold"
sudo apt-get install binutils-gold

echo "

"
echo ">>> Building runsc.."
sudo bazel clean
bazel build runsc

echo "

"
echo ">>> Copying build to /usr/local/bin"
sudo cp ./bazel-bin/runsc/linux_amd64_pure_stripped/runsc /usr/local/bin

echo "

"
echo ">>> Install of gvisor from source successful"
