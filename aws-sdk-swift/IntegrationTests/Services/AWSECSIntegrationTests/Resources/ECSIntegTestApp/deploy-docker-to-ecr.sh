#!/bin/bash

# Script will stop executing on first error
set -e

# Take in arguments from command line: account_id (required), region (optional), and repo_name (optional)
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <account_id> [REGION] [REPO_NAME]"
    exit 1
fi

# Assign variables
REGION="${2:-us-east-1}" # default value of us-east-1
REPO_NAME="${3:-ecs-integ-test}" # default value of ecs-integ-test
ACCOUNT_ID="$1"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Using region: $REGION, repo_name: $REPO_NAME, and account_id: $ACCOUNT_ID"

# Authenticate
$(aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI)

# Check if ECR repo exists
REPO_EXISTS=$(aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION 2>&1 || true)

if [[ $REPO_EXISTS == *"does not exist"* ]]; then
    echo "Creating repository named $REPO_NAME..."
    aws ecr create-repository --repository-name $REPO_NAME --region $REGION
    echo "Repository $REPO_NAME created successfully"
fi

# Build docker image
docker build -t $REPO_NAME .

# Tag the docker image for versioning
docker tag $REPO_NAME:latest $ECR_URI/$REPO_NAME:latest

# Push to ECR
docker push $ECR_URI/$REPO_NAME:latest

echo "Docker image pushed to ECR successfully"
