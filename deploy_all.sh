#!/bin/bash
#
# Script to deploy all OCL docker images to the corresponding ECR and ECS.
#
# Example of usage:
#
# AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret_key REGION=us-east-2 CLUSTER=oclqa SERVICE=ocl ./deploy_all.sh
#

set -e

AWS_CLI_TAG=2.1.1
SKIP_ECS=true

CREDENTIALS=""

if [ -n "$AWS_ACCESS_KEY_ID" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
fi
if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
fi
if [ -n "$REGION" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_DEFAULT_REGION=$REGION"
fi

echo ""
echo "1/7 Pushing postgres to ECR"
IMAGE=postgres TAG=12.3-alpine ./deploy.sh
echo ""
echo "2/7 Pushing redis to ECR"
IMAGE=redis TAG=6.0.6-alpine ./deploy.sh
echo ""
echo "3/7 Pushing elasticsearch to ECR"
IMAGE=elasticsearch TAG=7.8.1 ./deploy.sh
echo ""
echo "4/7 Pushing oclapi2 to ECR"
IMAGE=openconceptlab/oclapi2 AWS_IMAGE=oclapi2 TAG=qa ./deploy.sh
echo ""
echo "5/7 Pushing oclweb2 to ECR"
IMAGE=openconceptlab/oclweb2 AWS_IMAGE=oclweb2 TAG=qa ./deploy.sh
echo ""
echo "6/7 Pushing oclweb to ECR"
IMAGE=openconceptlab/oclweb AWS_IMAGE=oclweb TAG=qa ./deploy.sh

echo ""
echo "7/7 Deploying to ECS"
docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
 --service $SERVICE --force-new-deployment --region $REGION
