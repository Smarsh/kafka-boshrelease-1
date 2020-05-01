#!/bin/bash
set -eux

apt update
apt-get install git -y -f > /dev/null
apt-get install vim -y -f > /dev/null

git config --global user.email "dmidd87@gmail.com"

cd kafka-repo

echo "$BOSH_CLIENT"

echo "creating final release"

bosh create-release --final --version=2.4.1-1

#git add -A
#git commit -m "final release"
