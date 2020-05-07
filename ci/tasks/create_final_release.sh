#!/bin/bash
set -eux

# Download dependencies - Working on a docker container already containing these will remove later
apt update > /dev/null
apt-get install git -y -f > /dev/null
apt-get install vim -y -f > /dev/null

echo "Configuring files, keys, certs and directories"
echo "==="
echo "==="
GITHUB_REPO="https://github.com/Smarsh/cf-kafka-boshrelease"
git clone $GITHUB_REPO
echo "$BOSH_JUMPBOX_KEY" > jumpbox.key
echo "$BOSH_CA_CERT" > ca_cert.crt

echo "Configuring BOSH environment"
export BOSH_ENVIRONMENT=18.205.195.59
bosh alias-env $BOSH_ENVIRONMENT -e $BOSH_ENVIRONMENT --ca-cert ${PWD}/ca_cert.crt
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@${BOSH_ENVIRONMENT}:22?private-key=${PWD}/jumpbox.key

bosh deployments

## change directories into the master branch of the repository that is cloned, not the branched clone
export GITHUB_DIR=`echo $GITHUB_REPO | cut -d / -f 5`
cd $GITHUB_DIR

echo "Cutting a final release"
echo "==="
echo "==="

## Download all of the blobs and packages from the kafka-boshrelease bucket that is read only
bosh create-release --final --version=2 --tarball "../release_tarball/kafka.tgz" || true

## Change the bucket destination to smarshes bosh release blobs
sed -i 's/: kafka-boshrelease.*/: smarsh-bosh-release-blobs/' config/final.yml

## Move the private.yml from the pipeline branch into the current dir.  The private.yml being in config for the initial clone will break BOSH.
mv ../kafka-repo/config/private.yml config/

## Now that we've downloaded everything needed from the read only bucket, edited the final.yml and created a private.yml our release can be made.
bosh create-release --final --force --version=2.4.1-1 --tarball "../release_tarball/kafka-2.4.1-1.tgz"
