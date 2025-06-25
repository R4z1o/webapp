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
            ./talisman --scan --json > talisman_report.json || true

            # Generate the HTML report
            cat > talisman_report.html << 'EOF'
            <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Talisman Secret Scan Report</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        :root {
            --high-severity: #dc3545;
            --medium-severity: #fd7e14;
            --low-severity: #ffc107;
            --info-severity: #17a2b8;
            --success-color: #28a745;
            --light-bg: #f8f9fa;
            --dark-bg: #343a40;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            line-height: 1.6;
            color: #212529;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        header {
            background-color: var(--dark-bg);
            color: white;
            padding: 20px 0;
            margin-bottom: 30px;
        }
        header h1 {
            margin: 0;
            font-size: 28px;
        }
        header .subtitle {
            opacity: 0.8;
            font-size: 16px;
        }
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-top: 4px solid;
        }
        .summary-card.high {
            border-color: var(--high-severity);
        }
        .summary-card.medium {
            border-color: var(--medium-severity);
        }
        .summary-card.low {
            border-color: var(--low-severity);
        }
        .summary-card.info {
            border-color: var(--info-severity);
        }
        .summary-card .count {
            font-size: 32px;
            font-weight: bold;
            margin: 10px 0;
        }
        .summary-card .label {
            font-size: 14px;
            color: #6c757d;
        }
        .filters {
            background: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            align-items: center;
        }
        .filter-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .filter-group label {
            font-weight: 600;
            font-size: 14px;
        }
        select, input {
            padding: 8px 12px;
            border: 1px solid #ced4da;
            border-radius: 4px;
            font-size: 14px;
        }
        button {
            padding: 8px 16px;
            background-color: var(--dark-bg);
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.2s;
        }
        button:hover {
            background-color: #23272b;
        }
        .results-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 5px;
            overflow: hidden;
        }
        .results-table th {
            background-color: var(--dark-bg);
            color: white;
            padding: 12px 15px;
            text-align: left;
            font-weight: 600;
        }
        .results-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e9ecef;
            vertical-align: top;
        }
        .results-table tr:last-child td {
            border-bottom: none;
        }
        .results-table tr:hover {
            background-color: rgba(0,0,0,0.02);
        }
        .severity {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .severity.high {
            background-color: rgba(220, 53, 69, 0.1);
            color: var(--high-severity);
        }
        .severity.medium {
            background-color: rgba(253, 126, 20, 0.1);
            color: var(--medium-severity);
        }
        .severity.low {
            background-color: rgba(255, 193, 7, 0.1);
            color: var(--low-severity);
        }
        .file-path {
            font-family: monospace;
            word-break: break-all;
        }
        .commits-count {
            display: inline-block;
            background-color: #e9ecef;
            padding: 2px 6px;
            border-radius: 10px;
            font-size: 12px;
            margin-left: 5px;
        }
        .details-toggle {
            color: var(--dark-bg);
            cursor: pointer;
        }
        .details-content {
            display: none;
            padding: 10px;
            background-color: var(--light-bg);
            border-radius: 4px;
            margin-top: 10px;
            font-size: 13px;
        }
        .details-content.show {
            display: block;
        }
        .commit-hash {
            font-family: monospace;
            display: inline-block;
            margin-right: 5px;
            margin-bottom: 3px;
            background-color: #e9ecef;
            padding: 2px 5px;
            border-radius: 3px;
            font-size: 12px;
        }
        footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #6c757d;
            font-size: 14px;
        }
        .no-results {
            text-align: center;
            padding: 40px;
            color: #6c757d;
            background: white;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        @media (max-width: 768px) {
            .summary-cards {
                grid-template-columns: 1fr;
            }
            .filters {
                flex-direction: column;
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>Talisman Secret Scan Report</h1>
            <div class="subtitle">Comprehensive security scan for sensitive data in your repository</div>
        </div>
    </header>

    <div class="container">
        <div class="summary-cards">
            <div class="summary-card high">
                <div class="title">High Severity</div>
                <div class="count" id="high-count">0</div>
                <div class="label">Potential security risks</div>
            </div>
            <div class="summary-card medium">
                <div class="title">Medium Severity</div>
                <div class="count" id="medium-count">0</div>
                <div class="label">Suspicious patterns</div>
            </div>
            <div class="summary-card low">
                <div class="title">Low Severity</div>
                <div class="count" id="low-count">0</div>
                <div class="label">Warnings & informational</div>
            </div>
            <div class="summary-card info">
                <div class="title">Files Scanned</div>
                <div class="count" id="files-count">0</div>
                <div class="label">Total files analyzed</div>
            </div>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label for="severity-filter">Severity:</label>
                <select id="severity-filter">
                    <option value="all">All Severities</option>
                    <option value="high">High</option>
                    <option value="medium">Medium</option>
                    <option value="low">Low</option>
                </select>
            </div>
            <div class="filter-group">
                <label for="type-filter">Type:</label>
                <select id="type-filter">
                    <option value="all">All Types</option>
                    <option value="filecontent">File Content</option>
                    <option value="filesize">File Size</option>
                    <option value="filename">File Name</option>
                </select>
            </div>
            <div class="filter-group">
                <label for="search">Search:</label>
                <input type="text" id="search" placeholder="Filename or message...">
            </div>
            <button id="reset-filters">Reset Filters</button>
        </div>

        <table class="results-table">
            <thead>
                <tr>
                    <th>Severity</th>
                    <th>File</th>
                    <th>Type</th>
                    <th>Message</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody id="results-body">
                <!-- Results will be populated by JavaScript -->
            </tbody>
        </table>

        <div id="no-results" class="no-results" style="display: none;">
            <i class="fas fa-search" style="font-size: 24px; margin-bottom: 10px;"></i>
            <h3>No results found</h3>
            <p>Try adjusting your filters to see more results.</p>
        </div>
    </div>

    <footer>
        <div class="container">
            Report generated on <span id="report-date"></span> | Talisman v1.37.0
        </div>
    </footer>

    <script>
        // Sample data - in your real implementation, this would come from the JSON output
        const scanData = {
            "summary": {
                "types": {
                    "filecontent": 327,
                    "filesize": 0,
                    "filename": 2,
                    "warnings": 0,
                    "ignores": 0
                }
            },
            "results": [
                {
                    "filename": ".env",
                    "failure_list": [
                        {
                            "type": "filename",
                            "message": "The file name \".env\" failed checks against the pattern \\.?env",
                            "commits": ["aa73657d7ea505f3b55cf1f908129fe3f0136db2", "95c01f3351a533ec985df0d270120782fbf95815"],
                            "severity": "low"
                        },
                        {
                            "type": "filecontent",
                            "message": "Expected file to not contain base64 encoded texts such as: AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPx...",
                            "commits": [],
                            "severity": "high"
                        },
                        {
                            "type": "filecontent",
                            "message": "Potential secret pattern : AWS_ACCESS_KEY_ID=AKIAABCDEFGHIJKLMNOP",
                            "commits": ["aa73657d7ea505f3b55cf1f908129fe3f0136db2", "95c01f3351a533ec985df0d270120782fbf95815"],
                            "severity": "low"
                        },
                        {
                            "type": "filecontent",
                            "message": "Potential secret pattern : AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYABCDEFGHIJKLMNOP",
                            "commits": ["aa73657d7ea505f3b55cf1f908129fe3f0136db2", "95c01f3351a533ec985df0d270120782fbf95815"],
                            "severity": "high"
                        }
                    ]
                }
                // More results would be here in the real data
            ]
        };

        // Function to render the report
        function renderReport(data) {
            const resultsBody = document.getElementById('results-body');
            resultsBody.innerHTML = '';
            
            let highCount = 0;
            let mediumCount = 0;
            let lowCount = 0;
            let fileCount = data.results.length;

            data.results.forEach(file => {
                file.failure_list.forEach(failure => {
                    // Count severities
                    if (failure.severity === 'high') highCount++;
                    else if (failure.severity === 'medium') mediumCount++;
                    else lowCount++;

                    // Create row
                    const row = document.createElement('tr');
                    
                    // Severity cell
                    const severityCell = document.createElement('td');
                    const severitySpan = document.createElement('span');
                    severitySpan.className = `severity ${failure.severity}`;
                    severitySpan.textContent = failure.severity;
                    severityCell.appendChild(severitySpan);
                    
                    // File cell
                    const fileCell = document.createElement('td');
                    fileCell.className = 'file-path';
                    fileCell.textContent = file.filename;
                    
                    // Type cell
                    const typeCell = document.createElement('td');
                    typeCell.textContent = failure.type;
                    
                    // Message cell
                    const messageCell = document.createElement('td');
                    messageCell.textContent = failure.message;
                    
                    // Details cell
                    const detailsCell = document.createElement('td');
                    
                    if (failure.commits && failure.commits.length > 0) {
                        const toggle = document.createElement('span');
                        toggle.className = 'details-toggle';
                        toggle.innerHTML = `<i class="fas fa-chevron-down"></i> ${failure.commits.length} commits`;
                        toggle.onclick = function() {
                            const content = this.nextElementSibling;
                            content.classList.toggle('show');
                            this.querySelector('i').classList.toggle('fa-chevron-down');
                            this.querySelector('i').classList.toggle('fa-chevron-up');
                        };
                        
                        const content = document.createElement('div');
                        content.className = 'details-content';
                        failure.commits.forEach(commit => {
                            const commitSpan = document.createElement('span');
                            commitSpan.className = 'commit-hash';
                            commitSpan.textContent = commit.substring(0, 7);
                            commitSpan.title = commit;
                            content.appendChild(commitSpan);
                        });
                        
                        detailsCell.appendChild(toggle);
                        detailsCell.appendChild(content);
                    } else {
                        detailsCell.textContent = 'No commit history';
                    }
                    
                    // Append cells to row
                    row.appendChild(severityCell);
                    row.appendChild(fileCell);
                    row.appendChild(typeCell);
                    row.appendChild(messageCell);
                    row.appendChild(detailsCell);
                    
                    // Append row to table
                    resultsBody.appendChild(row);
                });
            });

            // Update summary counts
            document.getElementById('high-count').textContent = highCount;
            document.getElementById('medium-count').textContent = mediumCount;
            document.getElementById('low-count').textContent = lowCount;
            document.getElementById('files-count').textContent = fileCount;

            // Update report date
            document.getElementById('report-date').textContent = new Date().toLocaleString();
        }

        // Function to filter results
        function filterResults() {
            const severityFilter = document.getElementById('severity-filter').value;
            const typeFilter = document.getElementById('type-filter').value;
            const searchQuery = document.getElementById('search').value.toLowerCase();
            
            const rows = document.querySelectorAll('#results-body tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const severity = row.querySelector('.severity').className.includes(severityFilter);
                const type = row.cells[2].textContent.toLowerCase();
                const file = row.cells[1].textContent.toLowerCase();
                const message = row.cells[3].textContent.toLowerCase();
                
                const severityMatch = severityFilter === 'all' || row.querySelector('.severity').className.includes(severityFilter);
                const typeMatch = typeFilter === 'all' || type === typeFilter;
                const searchMatch = searchQuery === '' || 
                    file.includes(searchQuery) || 
                    message.includes(searchQuery) || 
                    type.includes(searchQuery);
                
                if (severityMatch && typeMatch && searchMatch) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            document.getElementById('no-results').style.display = visibleCount > 0 ? 'none' : 'block';
        }

        // Event listeners
        document.getElementById('severity-filter').addEventListener('change', filterResults);
        document.getElementById('type-filter').addEventListener('change', filterResults);
        document.getElementById('search').addEventListener('input', filterResults);
        document.getElementById('reset-filters').addEventListener('click', function() {
            document.getElementById('severity-filter').value = 'all';
            document.getElementById('type-filter').value = 'all';
            document.getElementById('search').value = '';
            filterResults();
        });

        // Initialize the report
        document.addEventListener('DOMContentLoaded', function() {
            // In your real implementation, you would fetch the JSON data here
            // For example:
            // fetch('talisman_report.json')
            //     .then(response => response.json())
            //     .then(data => renderReport(data));
            
            renderReport(scanData);
        });
    </script>
</body>
</html>
            EOF

            # Insert the JSON data into the HTML
            sed -i "s|const scanData = {.*};|const scanData = $(cat talisman_report.json);|" talisman_report.html

            mkdir -p talisman_report
            mv talisman_report.* talisman_report/
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
