pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                echo 'Building the application...'
                sh "docker build -t uwinchester/pfa_app ."
            }
        }
        stage ('push') {
            steps {
                echo 'Pushing the image to dockerhub...'
                sh 'docker login -u uwinchester -p youdou203'
                sh 'docker push uwinchester/pfa_app'
            }
        }
        stage ('deploy to tomcat') {
            steps {
                sh "docker run -p 8081"
            }
        }
    }

}