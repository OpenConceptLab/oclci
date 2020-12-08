#!/bin/bash
#
# Script to deploy the given docker image to the corresponding ECR and ECS.
#
# Example of usage:
#
# AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret_key REGION=us-east-2 CLUSTER=oclqa SERVICE=ocl \
#  IMAGE=openconceptlab/oclapi2 AWS_IMAGE=oclapi2 TAG=qa ./deploy.sh
#

set -e

if [ -z "$AWS_CLI_TAG" ]; then
  AWS_CLI_TAG=2.1.1
fi

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

if [ -z "$AWS_IMAGE" ]; then
  AWS_IMAGE=$IMAGE
fi

ACCOUNT_ID=$(docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG sts get-caller-identity --query Account --output text)

ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

PASSWORD=$(docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecr get-login-password --region $REGION)
docker login --username AWS --password $PASSWORD $ECR_URL
 
docker pull $IMAGE:$TAG

docker tag $IMAGE:$TAG $ECR_URL/$AWS_IMAGE:$TAG

docker push $ECR_URL/$AWS_IMAGE:$TAG

if [ -z "$SKIP_ECS" ]; then
  echo ""
  echo "Deploying to ECS"
  docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
   --service $SERVICE --force-new-deployment --region $REGION
  if [ "$SERVICE" -eq "ocl_api" ]; then
    echo "Deploying OCL API"
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_celery" --force-new-deployment --region $REGION
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_celery_concurrent" --force-new-deployment --region $REGION
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_celery_bulk_import_root" --force-new-deployment --region $REGION
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_celery_bulk_import_0_1" --force-new-deployment --region $REGION
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_celery_bulk_import_2_3" --force-new-deployment --region $REGION
    docker run --rm -v ~/.aws:/root/.aws $CREDENTIALS amazon/aws-cli:$AWS_CLI_TAG ecs update-service --cluster $CLUSTER \
     --service "ocl_flower" --force-new-deployment --region $REGION
  fi
fi
 
