pipeline {
    agent any
    stages {
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


        
        stage ('build') {
            steps {
                echo 'Building the application...'
                sh "docker build -t uwinchester/pfa_app ."
            }
        }
        stage('Container Scan') {
            steps {
                sh '''   
                    grype uwinchester/pfa_app > grype-report.txt
                    cat grype-report.txt 
                '''
            }
        }
        stage ('push') {
            steps {
                echo 'Pushing the image to dockerhub...'
                withCredentials([usernamePassword(credentialsId: 'jenkins-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                sh "docker login -u $DOCKER_USER -p $DOCKER_PASS"
                sh 'docker push uwinchester/pfa_app'
        }
    }
}


        stage ('deployement') {
            steps {
                echo 'deploying to tomcat'
                sh 'docker-compose down --rmi local --volumes --remove-orphans || true'
                sh 'docker rm -f tomcat-devsecops'
                sh 'docker rm -f nginx-devsecops'
                sh 'docker rm -f uwinchester/pfa_app'
                sh "docker-compose up -d"
            }
        }
        stage('DAST~') {
            steps{
                script {
                    sh 'mkdir -p zap-reports'

                    sh '''
                        docker pull zaproxy/zap-stable
                        docker run --rm \
                            -v "$WORKSPACE/zap-reports:/zap/wrk" \
                            -u $(id -u):$(id -g) \
                            -t zaproxy/zap-stable \
                            zap-full-scan.py \
                            -t http://104.248.252.219/ \
                            -r zap-report.html
                        '''
                    
                }
                echo "[INFO] ZAP scan completed. Check the report if the build fails."
                archiveArtifacts 'zap-reports/zap-report.html'
            }
        }
    }
    post {
        always {
            
            publishHTML target: [
                allowMissing: true,
                reportDir: './zap-reports/',
                reportFiles: 'zap-report.html', 
                reportName: 'zap-reports',
                keepAll: true
            ]
        }
    }
}
