#!/bin/bash
#
# Script to deploy all OCL docker images to the corresponding ECR and ECS.
#
# Example of usage:
#
# AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret_key REGION=us-east-2 ./push_all.sh
#

set -e

AWS_CLI_TAG=2.1.1

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

ACCOUNT_ID=$(docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

PASSWORD=$(docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecr get-login-password --region $REGION)
docker login --username AWS --password $PASSWORD $ECR_URL

echo ""
echo "1/8 Pushing postgres to ECR"
IMAGE=postgres 
TAG=12.3-alpine
docker pull $IMAGE:$TAG  
docker tag $IMAGE:$TAG $ECR_URL/$IMAGE:$TAG
docker push $ECR_URL/$IMAGE:$TAG
echo ""
echo "2/8 Pushing redis to ECR"
IMAGE=redis 
AWS_IMAGE=redis
TAG=6.0.6-alpine
docker pull $IMAGE:$TAG  
docker tag $IMAGE:$TAG $ECR_URL/$IMAGE:$TAG
docker push $ECR_URL/$IMAGE:$TAG
echo ""
echo "3/8 Pushing elasticsearch to ECR"
IMAGE=elasticsearch 
TAG=7.8.1
docker pull $IMAGE:$TAG  
docker tag $IMAGE:$TAG $ECR_URL/$IMAGE:$TAG
docker push $ECR_URL/$IMAGE:$TAG
echo ""
echo "4/8 Pushing oclapi2 to ECR"
IMAGE=openconceptlab/oclapi2 
AWS_IMAGE=oclapi2
docker pull $IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:qa
docker push $ECR_URL/$AWS_IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:demo
docker push $ECR_URL/$AWS_IMAGE:demo
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:staging
docker push $ECR_URL/$AWS_IMAGE:staging
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:production
docker push $ECR_URL/$AWS_IMAGE:production
echo ""
echo "5/8 Pushing oclfhir to ECR"
IMAGE=openconceptlab/oclfhir
AWS_IMAGE=oclfhir
docker pull $IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:qa
docker push $ECR_URL/$AWS_IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:demo
docker push $ECR_URL/$AWS_IMAGE:demo
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:staging
docker push $ECR_URL/$AWS_IMAGE:staging
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:production
docker push $ECR_URL/$AWS_IMAGE:production
echo ""
echo "6/8 Pushing oclweb2 to ECR"
IMAGE=openconceptlab/oclweb2
AWS_IMAGE=oclweb2 
docker pull $IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:qa
docker push $ECR_URL/$AWS_IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:demo
docker push $ECR_URL/$AWS_IMAGE:demo
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:staging
docker push $ECR_URL/$AWS_IMAGE:staging
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:production
docker push $ECR_URL/$AWS_IMAGE:production
echo ""
echo "7/8 Pushing oclweb to ECR"
IMAGE=openconceptlab/oclweb 
AWS_IMAGE=oclweb
docker pull $IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:qa
docker push $ECR_URL/$AWS_IMAGE:qa
docker tag $IMAGE:demo $ECR_URL/$AWS_IMAGE:demo
docker push $ECR_URL/$AWS_IMAGE:demo
docker tag $IMAGE:staging $ECR_URL/$AWS_IMAGE:staging
docker push $ECR_URL/$AWS_IMAGE:staging
docker tag $IMAGE:production $ECR_URL/$AWS_IMAGE:production
docker push $ECR_URL/$AWS_IMAGE:production
echo ""
echo "8/8 Pushing oclmsp to ECR"
IMAGE=openconceptlab/oclmsp
AWS_IMAGE=oclmsp
docker pull $IMAGE:qa
docker tag $IMAGE:qa $ECR_URL/$AWS_IMAGE:qa
docker push $ECR_URL/$AWS_IMAGE:qa
docker tag $IMAGE:demo $ECR_URL/$AWS_IMAGE:demo
docker push $ECR_URL/$AWS_IMAGE:demo
docker tag $IMAGE:staging $ECR_URL/$AWS_IMAGE:staging
docker push $ECR_URL/$AWS_IMAGE:staging
docker tag $IMAGE:production $ECR_URL/$AWS_IMAGE:production
docker push $ECR_URL/$AWS_IMAGE:production

