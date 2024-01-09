#!/bin/bash -eux
set -o pipefail

cd "$(dirname "$0")/.." || exit

APP_NAME="dockit-opensearch"

PROFILE=$1
OS_USERNAME=$2
OS_PASSWORD=$3

#  deploy stack
aws --profile "${PROFILE}" \
    cloudformation deploy \
    --stack-name $APP_NAME \
    --parameter-overrides OSUsername="${OS_USERNAME}" OSPassword="${OS_PASSWORD}" \
    --template-file ./iac/opensearch.yml \
    --capabilities CAPABILITY_IAM
