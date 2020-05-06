#!/bin/bash
set -eux

echo "Configuring files and directories"
echo "----"
mkdir ~/.ssh
echo "$GITHUB_PRIV_KEY" > ~/.ssh/id_rsa
git clone $GITHUB_REPO
# export GITHUB_DIR=`echo $GITHUB_REPO | cut -d / -f 5`
echo "$BOSH_JUMPBOX_KEY" > jumpbox.key
echo "$BOSH_CA_CERT" > ca_cert.crt

echo "Configuring BOSH environment"
bosh alias-env $BOSH_ENVIRONMENT -e $BOSH_ENVIRONMENT --ca-cert ${PWD}/ca_cert.crt
export BOSH_CLIENT=david.middleton@smarsh.com
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@${BOSH_ENVIRONMENT}:22?private-key=${PWD}/jumpbox.key

apt update
apt-get install git -y -f > /dev/null
apt-get install vim -y -f > /dev/null

## change directories into the master branch of the repository that is cloned, not the branched clone
export GITHUB_DIR=`echo $GITHUB_REPO | cut -d / -f 5`
cd $GITHUB_DIR

echo "creating final release"

## Download all of the blobs and packages
bosh create-release --final --version=2 --tarball "../release_tarball/kafka.tgz" || true

## Change the bucket destination
sed -i 's/: kafka-boshrelease.*/: smarsh-bosh-release-blobs/' config/final.yml

## Move the private.yml from the pipeline branch into the current dir
mv ../kafka-repo/config/private.yml config/

## Fake commit
git config --global user.email "you@example.com"; git add -A; git commit -m"m"

## Run the final release creation
bosh create-release --final --version=2.4.1-1 --tarball "../release_tarball/kafka-2.4.1-1.tgz"

## Validate the tar
ls -lat ../release_tarball/
