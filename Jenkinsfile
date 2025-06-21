pipeline {
    agent any

    environment {
        TRIVY_CACHE_DIR = '/tmp/trivy-cache' 
        DOCKER_IMAGE = 'uwinchester/pfa_app'
        SEMGREP_APP_TOKEN = credentials('SEMGREP_APP_TOKEN')  
    }
    
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
                '''
                archiveArtifacts allowEmptyArchive: true, artifacts: 'webapp/talisman_report/**', fingerprint: true
            }
            post {
                always {
                    echo "Talisman reports archived."
                }
            }
        }

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
        /*
        stage('SonarQube Analysis') {
            steps{
                withSonarQubeEnv(installationName: 'sonarQube') {
                  sh "mvn clean verify sonar:sonar -Dsonar.projectKey=jenkinsPipeline -Dsonar.projectName='jenkinsPipeline'"
                }
            }
        }
        
        */

        stage('Semgrep-Scan') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip3 install semgrep
                        semgrep ci
                    '''
                    // Note: remove the --disable-pro flag when we add more memory to the Jenkins server
                }
            }
        }

        stage('Generate SBOM') {  
            steps {  
                sh '''  
                syft scan dir:. --output cyclonedx-json=sbom.json  
                '''  
                archiveArtifacts allowEmptyArchive: true, artifacts: 'sbom*', fingerprint: true, followSymlinks: false, onlyIfSuccessful: true  
                sh ' rm -rf sbom*'  
            }
        }
        
        stage ('build') {
            steps {
                echo 'Building the application...'
                sh """
                    docker rmi ${DOCKER_IMAGE}|| true
                    docker build -t ${DOCKER_IMAGE} .
                    """
            }
        }
    stage('Infrastructure as a Code (IaaC) Scanning') {
    steps {
        script {

            sh'''
            find /var -name "trivy*" -exec rm -rf {} + 2>/dev/null || true
            find /var -name "javadb*" -exec rm -rf {} + 2>/dev/null || true
            '''
            // Verify image exists locally before scanning
            sh "docker inspect ${DOCKER_IMAGE}"
            
            // Install Trivy if missing
            sh '''
            if ! command -v trivy &> /dev/null; then
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
            fi
            '''
            
            // Setup cache
            sh "mkdir -p ${TRIVY_CACHE_DIR}"
            sh "trivy --cache-dir ${TRIVY_CACHE_DIR} image --download-db-only"
            
            // Run Trivy Scan
            sh """
                mkdir -p ${TRIVY_CACHE_DIR}/tmp
            
                TMPDIR=${TRIVY_CACHE_DIR}/tmp trivy \\
                    --cache-dir ${TRIVY_CACHE_DIR} image \\
                    --scanners vuln \\
                    --format json \\
                    --output trivy-report.json \\
                    --severity CRITICAL,HIGH \\
                    --ignore-unfixed \\
                    --skip-version-check \\
                    ${DOCKER_IMAGE}
            """

            archiveArtifacts 'trivy-report.json'
            
            // Critical vulnerability check
            def criticalFound = sh(
                script: "grep -q 'CRITICAL' trivy-report.txt",
                returnStatus: true
            ) == 0

            if (criticalFound) {
                error "Critical vulnerabilities found in container image"
            }
        }
    }
}
        stage ('push') {
    steps {
        echo 'Pushing the image to dockerhub...'
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PWD'
        )]) {
            sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PWD}"
            sh 'docker push ${DOCKER_IMAGE}'
        }
    }
}
        stage ('deployement') {
            steps {
                echo 'deploying to tomcat'
                sh 'docker compose down --rmi local --volumes --remove-orphans || true'
                sh 'docker rm -f tomcat-devsecops'
                sh 'docker rm -f nginx-devsecops'
                sh 'docker rm -f uwinchester/pfa_app'
                sh "docker compose up -d"
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
            // Publish ZAP Report 
            publishHTML target: [
                allowMissing: true,
                reportDir: './zap-reports/',
                reportFiles: 'zap-report.html', 
                reportName: 'zap-reports',
                keepAll: true
            ]

            // Cleanup Trivy cache 
            sh "rm -rf ${TRIVY_CACHE_DIR} || true"
        }
    }
}
