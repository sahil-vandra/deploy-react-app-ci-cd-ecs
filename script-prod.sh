#!/bin/bash

AWS_ACCOUNT_ID="997817439961"
AWS_DEFAULT_REGION="ap-south-1" 
IMAGE_REPO_NAME="sahil-react-demo"
IMAGE_TAG="sahil-react-demo"
CLUSTER_NAME="sahil-react-demo-cluster"
SERVICE_NAME="sahil-react-demo-service"
TASK_DEFINITION_NAME="sahil_react_demo_task_def"
ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"

# docker image prune -a
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

# login in to aws ecr
# if not logged in the fire this command : "sudo chmod 666 /var/run/docker.sock"
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 997817439961.dkr.ecr.ap-south-1.amazonaws.com

# build new image
# docker build -t 997817439961.dkr.ecr.ap-south-1.amazonaws.com/sahil-react-demo:sahil-react-demo .
docker build -t ${ECR_IMAGE} .

# push image in aws ecr
# docker push 997817439961.dkr.ecr.ap-south-1.amazonaws.com/sahil-react-demo:sahil-react-demo
docker push ${ECR_IMAGE}

# get role arn store in variable 
ROLE_ARN=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.executionRoleArn`
echo "ROLE_ARN= " $ROLE_ARN

# get family store in variable 
FAMILY=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.family`
echo "FAMILY= " $FAMILY

# get name arn store in variable 
NAME=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.containerDefinitions[].name`
echo "NAME= " $NAME

# find and replace some content in task-definition file
sed -i "s#BUILD_NUMBER#$ECR_IMAGE#g" task-definition.json
sed -i "s#REPOSITORY_URI#$REPOSITORY_URI#g" task-definition.json
sed -i "s#ROLE_ARN#$ROLE_ARN#g" task-definition.json
sed -i "s#FAMILY#$FAMILY#g" task-definition.json
sed -i "s#NAME#$NAME#g" task-definition.json

# Get task definition from the aws console
TASK_DEF_REVISION=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.revision`
echo "TASK_DEF_REVISION= " $TASK_DEF_REVISION

echo "task definition =================================================================="
cat task-definition.json
echo "task definition =================================================================="

# register new task definition from new generated task definition file
aws ecs register-task-definition --cli-input-json file://task-definition.json --region="${AWS_DEFAULT_REGION}"

# deregister previous task definiiton
aws ecs deregister-task-definition --region ap-south-1 --task-definition ${TASK_DEFINITION_NAME}:${TASK_DEF_REVISION}

# update servise
aws ecs update-service --region ap-south-1 --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" --task-definition "${TASK_DEFINITION_NAME}" --force-new-deployment 
