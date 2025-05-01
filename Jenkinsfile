pipeline {
    agent any
    stages {
        stage ('owasp-dependency-check') {
            steps {
                echo 'OWASP dependecy check'
                sh "docker build --target dependency-check -t uwinchester/pfa_app ."
            }
        }
        stage ('build') {
            steps {
                echo 'Building the application...'
                sh "docker build --target build -t uwinchester/pfa_app ."
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
                echo 'deploying to tomcat'
                sh "docker run -d -p 8881:8080 uwinchester/pfa_app"
            }
        }
    }

}