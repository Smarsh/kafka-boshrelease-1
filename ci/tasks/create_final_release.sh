#!/bin/bash
set -eux

apt-get install git -y -f > /dev/null
echo $BOSH_CLIENT_SECRET

git config --global user.email "dmidd87@gmail.com"

echo "creating final release"

bosh create-release --final --version=2.4.1-1

git add -A
git commit -m "final release"
