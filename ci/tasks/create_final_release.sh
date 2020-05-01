#!/bin/bash
set -eux

#git config --global user.email "dmidd87@gmail.com"

cd kafka-repo

echo "creating final release"

bosh create-release --final --version=2.4.1-1

#git add -A
#git commit -m "final release"
