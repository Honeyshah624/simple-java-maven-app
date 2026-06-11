pipeline {
    agent any

    tools {
        maven 'Maven'
    }

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'

        
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

        stage('Checkout Code') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/Honeyshah624/simple-java-maven-app.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Run Unit Tests') {
            steps {
                sh 'mvn test'
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

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "Pushing Docker image: ${DOCKER_IMAGE}"
                    docker push ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Deploy to Minikube') {
            steps {
                sh '''
                    echo "Deploying Java Maven app to Minikube"

                    kubectl delete job ${JOB_NAME} -n ${KUBE_NAMESPACE} --ignore-not-found=true

                    sed "s|DOCKER_IMAGE_PLACEHOLDER|${DOCKER_IMAGE}|g" k8s/job.yaml | kubectl apply -f -

                    kubectl get jobs -n ${KUBE_NAMESPACE}
                    kubectl get pods -n ${KUBE_NAMESPACE} -l app=${JOB_NAME}
                '''
            }
        }

        stage('Verify Job Logs') {
            steps {
                sh '''
                    echo "Waiting for Kubernetes Job to complete..."

                    kubectl wait --for=condition=complete job/${JOB_NAME} -n ${KUBE_NAMESPACE} --timeout=120s

                    POD_NAME=$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=${JOB_NAME} -o jsonpath='{.items[0].metadata.name}')

                    echo "Pod Name: $POD_NAME"
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

        always {
            sh '''
                docker logout || true
            '''
        }
    }
}