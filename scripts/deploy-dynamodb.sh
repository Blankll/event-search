#!/bin/bash -eux
set -o pipefail

cd "$(dirname "$0")/.." || exit

APP_NAME="event-search-dynamodb"

PROFILE=$1
TABLE_NAME=$2

#  deploy stack
aws --profile "${PROFILE}" \
    cloudformation deploy \
    --stack-name $APP_NAME \
    --parameter-overrides TableName="${TABLE_NAME}" \
    --template-file ./iac/dynamodb.yml \
    --capabilities CAPABILITY_IAM
