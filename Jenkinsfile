pipeline {
    agent any
    stages {
        stage ('OWASP-dependency-check') {
            steps {
                echo 'dependency check using OWASP'
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-check'
                dependencyCheckPublisher pattern:''
                archiveArtifacts allowEmptyArchive: true, artifacts: 'dependency-check-report.xml', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true
                sh "rm -rf dependency-check-report.xml*"
            }
        }
        stage ('SCA using snyk') {
            steps {
                snykSecurity (
                    snykInstallation: 'snyk',
                    snykTokenId: '79230cba-8022-423d-80b0-1c625dc7b13a'
                )
                
            }
        }
        stage ('Check-Git-Secrets') {
            tools {
                maven 'mvn'
            }
            steps {
                sh 'rm trufflehog || true'
                sh 'docker pull gesellix/trufflehog'
                sh 'docker run --rm trufflesecurity/trufflehog github --repo https://github.com/R4z1o/webapp.git > trufflehog'
                sh 'cat trufflehog'
            }
        }

        stage('SonarQube Analysis') {
            steps{
                withSonarQubeEnv(installationName: 'sonarQube') {
                  sh "mvn clean verify sonar:sonar -Dsonar.projectKey=jenkinsPipeline -Dsonar.projectName='jenkinsPipeline'"
                }
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

        stage ('deploy to tomcat for DAST') {
            steps {
                echo 'deploying to tomcat'
                sh 'docker-compose down --volumes --remove-orphans'
                sh 'docker rm -f pfa_app'
                sh "docker-compose up -d"
            }
        }
        stage('DAST') {
            steps{
                script {
                    sh '''
                        docker pull zaproxy/zap-stable
                        docker run --rm \
                            -t owasp/zap-stable \
                            zap-baseline.py \
                            -t http://http://104.248.252.219:8081
                        '''
                }
            }
        }
    }
}
