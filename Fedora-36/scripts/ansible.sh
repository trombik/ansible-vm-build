#!/bin/bash
set -e
set -u
set -x

dnf -y install ansible rsync curl python3-libselinux
