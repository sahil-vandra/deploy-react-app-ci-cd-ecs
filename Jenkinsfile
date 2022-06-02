pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID="997817439961"
        AWS_DEFAULT_REGION="ap-south-1" 
        IMAGE_REPO_NAME="sahil-react-demo"
        IMAGE_TAG="sahil-react-demo-img"
        CLUSTER_NAME="sahil-react-demo-cluster"
        SERVICE_NAME="sahil-react-demo-service"
        TASK_DEFINITION_NAME="sahil_react_demo"
        DESIRED_COUNT="1"
    }
    
    stages {
        
        stage('Trigger pipeline and clone code') {
            steps {
                git branch: 'main', url: 'https://github.com/sahil-vandra/react-app-ci-cd-ecs-deployment.git'
                               
                sh "chmod +x -R ${env.WORKSPACE}"
                sh "./script-prod.sh"
            }
        }
      
    }
}
