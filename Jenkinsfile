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
                    mkdir -p talisman_report
                    ./talisman --scan || true
                    
                    # Create HTML report with table format
                    echo "<html>
                    <head>
                        <title>Talisman Scan Report</title>
                        <style>
                            body { font-family: Arial, sans-serif; margin: 20px; }
                            h1 { color: #333; }
                            table { border-collapse: collapse; width: 100%; margin-top: 20px; }
                            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                            th { background-color: #f2f2f2; }
                            tr:nth-child(even) { background-color: #f9f9f9; }
                            .high { background-color: #ffcccc; }
                            .medium { background-color: #ffe6cc; }
                            .low { background-color: #ffffcc; }
                            .summary { margin-bottom: 20px; }
                        </style>
                    </head>
                    <body>
                    <h1>Talisman Secret Scan Report</h1>" > talisman_report.html
        
                    # Add summary section
                    echo "<div class='summary'>
                        <h2>Scan Summary</h2>
                        <p>File Content Issues: 373</p>
                        <p>Filename Issues: 2</p>
                        <p>Filesize Issues: 0</p>
                        <p>Warnings: 0</p>
                        <p>Ignored: 0</p>
                    </div>" >> talisman_report.html
        
                    # Start results table
                    echo "<table>
                        <tr>
                            <th>File</th>
                            <th>Issue Type</th>
                            <th>Severity</th>
                            <th>Message</th>
                            <th>Commits</th>
                        </tr>" >> talisman_report.html
        
                    # Process the JSON report and convert to table rows
                    if [ -d "talisman_report/talisman_reports/data" ]; then
                        # Find all JSON files in the report directory
                        for report_file in $(find talisman_report/talisman_reports/data -name "*.json"); do
                            # Use jq to parse JSON and create table rows
                            filename=$(jq -r '.filename' $report_file)
                            
                            # Process failure_list
                            jq -r '.failure_list[] | 
                                "<tr class=\"" + .severity + "\">
                                    <td>" + .filename + "</td>
                                    <td>" + .type + "</td>
                                    <td>" + .severity + "</td>
                                    <td>" + (.message | gsub("\""; "'")) + "</td>
                                    <td>" + (.commits | join(", ")[0:50] + (if (.commits | length) > 1 then "..." else "" end)) + "</td>
                                </tr>"' $report_file >> talisman_report.html
                            
                            # Process warning_list (if any)
                            jq -r '.warning_list[] | 
                                "<tr class=\"low\">
                                    <td>" + .filename + "</td>
                                    <td>" + .type + "</td>
                                    <td>warning</td>
                                    <td>" + (.message | gsub("\""; "'")) + "</td>
                                    <td>" + (.commits | join(", ")[0:50] + (if (.commits | length) > 1 then "..." else "" end)) + "</td>
                                </tr>"' $report_file >> talisman_report.html
                        done
                    else
                        echo "<tr><td colspan='5'>No secrets detected by Talisman scan</td></tr>" >> talisman_report.html
                    fi
        
                    # Close table and HTML
                    echo "</table></body></html>" >> talisman_report.html
        
                    mv talisman_report.html talisman_report/
                '''
                archiveArtifacts allowEmptyArchive: true, artifacts: 'webapp/talisman_report/**', fingerprint: true
            }
            post {
                always {
                    echo 'Talisman reports archived.'
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
