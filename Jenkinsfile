pipeline {
    agent any
    stages {
        stage ('owasp-dependency-check') {
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-check'
                dependencyCheckPublisher pattern:''
                archiveArtifacts allowEmptyArchive: true, artifacts: 'dependency-check-report.xml', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
                sh "rm -rf dependency-check-report.xml*"
            }
        }
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
                echo 'deploying to tomcat'
                sh "docker run -d -p 8881:8080 uwinchester/pfa_app"
            }
        }
    }

}