pipeline {
    agent any

    environment {
        TRIVY_CACHE_DIR = '/tmp/trivy-cache' 
        DOCKER_IMAGE = 'uwinchester/pfa_app'   
    }
    
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

        /*stage('SonarQube Analysis') {
            steps{
                withSonarQubeEnv(installationName: 'sonarQube') {
                  sh "mvn clean verify sonar:sonar -Dsonar.projectKey=jenkinsPipeline -Dsonar.projectName='jenkinsPipeline'"
                }
            }
        }*/

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
                sh "docker build -t uwinchester/pfa_app ."
            }
        }
        stage('Container Scan') {
            steps {
                script {
                    // Part A: Install Trivy if missing
                    sh '''
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                    fi
                    '''
                    
                    // Part B: Create cache and update DB
                    sh "mkdir -p ${TRIVY_CACHE_DIR}"
                    sh "trivy --cache-dir ${TRIVY_CACHE_DIR} image --download-db-only"
                    
                    // Part C: Run Grype 
                    sh '''   
                        grype ${DOCKER_IMAGE}:${BUILD_NUMBER} > grype-report.txt
                        cat grype-report.txt 
                    '''
                    archiveArtifacts 'grype-report.txt'
                    
                    // Part D: Run Trivy Scan 
                    sh """
                        trivy --cache-dir ${TRIVY_CACHE_DIR} image \
                            --format template \
                            --template "@contrib/html.tpl" \
                            --output trivy-report.html \
                            --severity CRITICAL,HIGH \
                            --ignore-unfixed \
                            ${DOCKER_IMAGE}:${BUILD_NUMBER}
                            
                        trivy --cache-dir ${TRIVY_CACHE_DIR} image \
                            --format json \
                            --output trivy-report.json \
                            --severity CRITICAL,HIGH \
                            --ignore-unfixed \
                            ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    """
                    archiveArtifacts 'trivy-report.*'
                    
                    // Part E: Fail build if critical vulns found
                   /* def trivyResults = readJSON file: 'trivy-report.json'
                    if (trivyResults.Results.any { it.Vulnerabilities?.any { it.Severity == 'CRITICAL' } }) {
                        error "Critical vulnerabilities found in container image - build failed"
                    } */
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
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
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
           // Publish Trivy HTML Report
            publishHTML target: [
                allowMissing: true,
                reportDir: '.',
                reportFiles: 'trivy-report.html',
                reportName: 'Container Scan (Trivy)',
                keepAll: true
            ]
            
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
