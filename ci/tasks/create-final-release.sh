#!/bin/bash
set -eux

ROOT_DIR=$(pwd)

echo "Configuring files, keys, certs and directories"
echo "==="
echo "==="
GITHUB_REPO="kafka-repo"
PRERELEASE_REPO=../kafka-prerelease-repo
BOSH_RELEASE_VERSION=$(cat ${ROOT_DIR}/version/version)


git clone $GITHUB_REPO $PROMOTED_REPO

echo "$jumpbox_key" | jq -r .private_key > jumpbox.key
echo "$ca_cert" | jq -r .certificate > ca_cert.crt

echo "Configuring BOSH environment"
bosh alias-env $BOSH_ENVIRONMENT -e $BOSH_ENVIRONMENT --ca-cert ${PWD}/ca_cert.crt
export BOSH_ALL_PROXY=ssh+socks5://jumpbox@${BOSH_ENVIRONMENT}:22?private-key=${PWD}/jumpbox.key

## change directories into the master branch of the repository that is cloned, not the branched clone
pushd $PRERELEASE_REPO

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

echo "Cutting a final release"
echo "==="
echo "==="

## Download all of the blobs and packages from the kafka-boshrelease bucket that is read only

cp config/final.yml config/final.yml.old
    
    cat << EOF > config/final.yml
---
blobstore:
  provider: s3
  options:
    bucket_name: ${BLOBSTORE}
name: kafka
EOF

## Create private.yml for BOSH to use our AWS keys
    cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

bosh create-release --final --version=${BOSH_RELEASE_VERSION} --tarball "../s3-rc-release/kafka-${BOSH_RELEASE_VERSION}.tgz"
mv config/final.yml.old config/final.yml

git status
#git add -A
#git status
#git commit -m "Adding final release, ${BOSH_RELEASE_VERSION} via concourse"

popd