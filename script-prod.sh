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
# docker system prune -a
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

# login in to aws ecr
# if not logged in the fire this command : "sudo chmod 666 /var/run/docker.sock"
echo "-------------------------------------- login in to ecr ------------------------------------------------"
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 997817439961.dkr.ecr.ap-south-1.amazonaws.com
echo "--------------------------------------- login in to ecr succeed ---------------------------------------"

# build new image
# docker build -t 997817439961.dkr.ecr.ap-south-1.amazonaws.com/sahil-react-demo:sahil-react-demo .
echo "--------------------------------------- start docker image building -----------------------------------"
docker build -t ${ECR_IMAGE} .
echo "--------------------------------------- docker image build end ----------------------------------------"

# push image in aws ecr
# docker push 997817439961.dkr.ecr.ap-south-1.amazonaws.com/sahil-react-demo:sahil-react-demo
echo "------------------------------------------ start docker image push ------------------------------------"
docker push ${ECR_IMAGE}
echo "------------------------------------------ docker image pushed ----------------------------------------"

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

echo "--------------------------------------------- task definition -----------------------------------------"
cat task-definition.json
echo "-------------------------------------------- task definition ------------------------------------------"

# register new task definition from new generated task definition file
echo "-------------------------------------- registering new task definition --------------------------------"
aws ecs register-task-definition --cli-input-json file://task-definition.json --region="${AWS_DEFAULT_REGION}"
echo "------------------------------------ new task definition registered -----------------------------------"

# deregister previous task definiiton
echo "--------------------------------- deregistering previous task definition------------------------------"
aws ecs deregister-task-definition --region ap-south-1 --task-definition ${TASK_DEFINITION_NAME}:${TASK_DEF_REVISION}
echo "--------------------------------- previous task definition deregistered -------------------------------"

# update servise
echo "------------------------------------------ updare new service -----------------------------------------"
aws ecs update-service --region ap-south-1 --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" --task-definition "${TASK_DEFINITION_NAME}" --force-new-deployment 
echo "----------------------------------------- new service updated -----------------------------------------"

echo "---------------------------------------------- service ------------------------------------------------"
aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE_NAME}"
echo "---------------------------------------------- service ------------------------------------------------"


SERVICE_TASK_STATUS=`aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE_NAME}" | jq .deployments[].runningCount`
echo "-------------------------------------------------------------------------------------------------------"
echo "SERVICE_TASK_STATUS: " $SERVICE_TASK_STATUS

# until SERVICE_TASK_STATUS=1
# do
#   sleep 5
# done

# SERVICE_TASK_STATUS=`aws ecs describe-services --cluster "${CLUSTER_NAME}" --services "${SERVICE_NAME}" | jq .deployments[].runningCount`
# echo "-------------------------------------------------------------------------------------------------------"
# echo "SERVICE_TASK_STATUS: " $SERVICE_TASK_STATUS
