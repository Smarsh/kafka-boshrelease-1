#!/bin/bash
set -eux

echo "Configuring files, keys, certs and directories"
echo "==="
echo "==="
GITHUB_REPO="kafka-repo"
PROMOTED_REPO='kafka-repo-release'
git clone $GITHUB_REPO $PROMOTED_REPO

echo "$jumpbox_key" > jumpbox.key
echo "$ca_cert" > ca_cert.crt

echo "Configuring BOSH environment"
bosh alias-env $BOSH_ENVIRONMENT -e $BOSH_ENVIRONMENT --ca-cert ${PWD}/ca_cert.crt
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@${BOSH_ENVIRONMENT}:22?private-key=${PWD}/jumpbox.key

## change directories into the master branch of the repository that is cloned, not the branched clone
pushd $PROMOTED_REPO

echo "Cutting a final release"
echo "==="
echo "==="

## Download all of the blobs and packages from the kafka-boshrelease bucket that is read only
echo bosh create-release --final --version=123 --tarball "../s3-rc-release/kafka-*.tgz" || true

## Change the bucket destination to smarshes bosh release blobs
sed -i 's/: kafka-boshrelease.*/: smarsh-bosh-release-blobs/' config/final.yml

## Create private.yml for BOSH to use our AWS keys
cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

## Now that we've downloaded everything needed from the read only bucket, edited the final.yml and created a private.yml our release can be made.
echo bosh create-release --final --force --version=2.4.1-1 --tarball "../s3-rc-release/kafka-*.tgz"
popd