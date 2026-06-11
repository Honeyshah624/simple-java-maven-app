pipeline {
    agent any

    tools {
        maven 'Maven'
    }

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'
        DOCKERHUB_USERNAME = 'honeyshah062'

        IMAGE_NAME = 'simple-java-maven-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

        KUBE_NAMESPACE = 'default'
        JOB_NAME = 'simple-java-maven-app'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {

        stage('Build Maven App') {
            steps {
                sh 'mvn -B clean package'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image: ${DOCKER_IMAGE}"
                    docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                sh '''
                    echo "Deploying image ${DOCKER_IMAGE} to Minikube"

                    kubectl delete job ${JOB_NAME} -n ${KUBE_NAMESPACE} --ignore-not-found=true

                    sed "s|DOCKER_IMAGE_PLACEHOLDER|${DOCKER_IMAGE}|g" k8s/job.yaml | kubectl apply -f -

                    kubectl get jobs -n ${KUBE_NAMESPACE}
                    kubectl get pods -n ${KUBE_NAMESPACE} -l app=${JOB_NAME}
                '''
            }
        }

        stage('Verify App Logs') {
            steps {
                sh '''
                    echo "Waiting for Kubernetes Job to complete..."

                    kubectl wait --for=condition=complete job/${JOB_NAME} -n ${KUBE_NAMESPACE} --timeout=120s

                    POD_NAME=$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=${JOB_NAME} -o jsonpath='{.items[0].metadata.name}')

                    echo "Application Logs:"
                    kubectl logs $POD_NAME -n ${KUBE_NAMESPACE}
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Java Maven app deployed and executed in Minikube.'
        }

        failure {
            echo 'Pipeline failed. Please check Jenkins console output.'
        }
    }
}