pipeline {
    agent any
    stages {
        stage('Secret Scan with Talisman') {
            steps {
                sh '''
                    echo "[INFO] Cloning repo for Talisman scan"
                    rm -rf webapp talisman_report || true
                    git clone https://github.com/R4z1o/webapp.git webapp
                    cd webapp

                    echo "[INFO] Installing Talisman"
                    curl -L https://github.com/thoughtworks/talisman/releases/download/v1.37.0/talisman_linux_amd64 -o talisman
                    chmod +x talisman

                    echo "[INFO] Running Talisman Scan"
                    ./talisman --scan || true

                    ../talisman-to-html.sh talisman_report/talisman_reports/data/report.json output.html

                '''
                archiveArtifacts allowEmptyArchive: true, artifacts: 'webapp/talisman_report/**', fingerprint: true
            }
            post {
                always {
                    echo "Talisman reports archived."
                }
            }
        }
        stage ('Git Secrets Scanning') {
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
        stage ('local secrets leaks scan') {
            steps {
                sh 'mkdir -p gitleaks-reports'
                sh 'docker pull zricethezav/gitleaks'
                sh '''
                    docker run --rm \
                    -v ./:/repo \
                    -v $workspace/gitleaks-reports:/output \
                    zricethezav/gitleaks detect \
                    --source=/repo \
                    --report-path=/output/report.json || true
                '''
                sh 'cat $workspace/gitleaks-reports/report.json'
            }


        }

        stage ('build') {
            steps {
                echo 'Building the application...'
                sh "docker build -t uwinchester/pfa_app ."
            }
        }
        stage('Infrastructure as Code (IaC) scanning') {
            steps {
                script {
                    sh '''  
                        grype uwinchester/pfa_app > grype-report.txt
                        cat grype-report.txt 
                    '''
                }
            }
        }
        stage ('push') {
            steps {
                echo 'Pushing the image to dockerhub...'
                withCredentials([usernamePassword(credentialsId: 'jenkins-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                sh "docker login -u $DOCKER_USER -p $DOCKER_PASS"
                sh 'docker push uwinchester/pfa_app'}
            }
        }



        stage ('deployement') {
            steps {
                echo 'deploying for testing'
                sh 'docker-compose down --rmi local --volumes --remove-orphans || true'
                sh 'docker rm -f tomcat-devsecops'
                sh 'docker rm -f nginx-devsecops'
                sh 'docker rm -f uwinchester/pfa_app'
                sh "docker-compose -f docker-compose.yml up -d"
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
        stage ('WAF'){
            steps{
                echo 'deployment'
                sh 'docker-compose down --rmi local --volumes --remove-orphans || true'
                sh 'docker rm -f tomcat-devsecops-waf'
                sh 'docker rm -f nginx-devsecops-waf'
                sh 'docker rm -f uwinchester/pfa_app'
                sh "docker-compose -f docker-compose-waf.yml up -d"
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
