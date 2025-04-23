pipeline {
    agent any
    stages {
        steps {
            stages {
                echo 'Building the application...'
                sh "docker build ."
            }
        }
    }

}