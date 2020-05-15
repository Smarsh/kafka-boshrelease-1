#!/usr/bin/env bash

set -euo pipefail

if [[ $(echo $TERM | grep -v xterm) ]]; then
  export TERM=xterm
fi

SHELL=/bin/bash
ROOT_DIR=$(pwd)
USE_PIPELINE=0

export ROOT_PATH=${PWD}
export DEV_RELEASE_DIR=${ROOT_PATH}/s3-dev-release/kafka-dev-release.tgz
INPUT_DIR=git-bosh-final-release
OUTPUT_DIR=create-release
PROMOTED_REPO=${INPUT_DIR}-pr

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)


# this allows this script to run in Concourse and locally
[[ -d ./${INPUT_DIR} ]] && USE_PIPELINE=1

[[ ${USE_PIPELINE} -ne 0 ]] && pushd ./${INPUT_DIR}

VERSION_FILE="$(pwd)/VERSIONS"

[[ -f ${VERSION_FILE} ]] && source ${VERSION_FILE}
KAFKA_VERSION=${KAFKA_VERSION:?required}
KAFKA_SEMVER=$(echo ${KAFKA_VERSION} | awk -F- '{print $1}')

# 
declare -i KAFKA_RELEASE_VERSION=0
KAFKA_RELEASE_VERSION=$(echo ${KAFKA_VERSION} | awk -F- '{print int($2)}')

# increment release version
((++KAFKA_RELEASE_VERSION))

VERSION=${KAFKA_SEMVER}-${KAFKA_RELEASE_VERSION}

if [[ ! -d ../${DEV_RELEASE_DIR} ]] ; then 
  tarBallFile=./kafka-dev-release.tgz
else
  tarBallFile=../${DEV_RELEASE_DIR}/kafka-dev-release.tgz
fi


printf "\n${BOLD}${GREEN}Create final release${RESET}\n"

echo git config --global user.email "ci@localhost"
echo git config --global user.name "CI Bot"

popd

pushd ./bosh-dns-release
tag_name="v${VERSION}"

tag_annotation="Final release ${VERSION} tagged via concourse"

git tag -a "${tag_name}" -m "${tag_annotation}"
popd

git clone ./bosh-dns-release $PROMOTED_REPO

pushd $PROMOTED_REPO
git status

git checkout master
git status

cat > config/final.yml <<EOF
---
blobstore:
provider: s3
options:
  bucket_name: smarsh-bosh-release-blobs
name: kafka
EOF

cat > config/private.yml <<EOF
---
blobstore:
provider: s3
options:
  credentials_source: env_or_profile
EOF

echo bosh finalize-release --version $VERSION $DEV_RELEASE_PATH
echo bosh create-release --final --name kafka --version=${VERSION} --timestamp-version --tarball=${tarBallFile}

git add -A
git status

git commit -m "Adding final release $VERSION via concourse"
popd


[[ $USE_PIPELINE -ne 0 ]] && popd

###
