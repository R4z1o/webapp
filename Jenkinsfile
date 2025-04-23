pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                echo 'Building the application...'
                sh "docker build -t myapp ."
            }
        }
    }

}