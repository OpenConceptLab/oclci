#!/bin/bash
#
# Script to deploy the given docker image to the corresponding ECR and ECS.
#
# Example of usage:
#
# AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret_key AWS_REGION=us-east-2 \
#  AWS_ACCOUNT_ID=account_id AWS_CLUSTER=oclqa SERVICE=ocl \
#  IMAGE_REPO=openconceptlab IMAGE_NAME=oclapi2 TAG=qa ./deploy.sh
#

set -e

if [ -n "$AWS_ACCESS_KEY_ID" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
fi
if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
fi
if [ -n "$AWS_REGION" ]; then
  CREDENTIALS="$CREDENTIALS -e AWS_DEFAULT_REGION=$AWS_REGION"
fi

AWS_ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli ecr get-login-password --region $AWS_REGION \
 | docker login --username AWS --password-stdin $AWS_ECR_URL

docker tag $IMAGE_REPO/$IMAGE_NAME:$TAG $AWS_ECR_URL/$IMAGE_NAME:$TAG

docker push $AWS_ECR_URL/$IMAGE_NAME:$TAG

docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli ecs update-service --cluster $CLUSTER \
 --service $SERVICE --force-new-deployment --region $AWS_REGION
