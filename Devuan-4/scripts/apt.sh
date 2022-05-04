#!/bin/bash

set -e
set -x

# Disable periodic activities of apt, which causes `apt` tasks to fail by
# holding a lock
sudo -S tee -a /etc/apt/apt.conf.d/10disable-periodic <<EOF
APT::Periodic::Enable "0";
EOF

# Retry when fetching files fails
sudo -S tee -a /etc/apt/apt.conf.d/10retry <<EOF
Acquire::Retries "10";
EOF

sudo apt-get update
sudo apt-get -y install software-properties-common

source /etc/os-release
# XXX this should work, but does not
# sudo apt-add-repository "deb http://deb.devuan.org/merged beowulf-backports main"
echo "deb http://deb.devuan.org/merged ${VERSION_CODENAME}-backports main" | sudo tee -a /etc/apt/sources.list

sudo apt-get update
sudo apt-get -y -t ${VERSION_CODENAME}-backports install python3 ansible rsync
