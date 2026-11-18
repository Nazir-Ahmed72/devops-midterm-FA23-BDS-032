pipeline {
    agent any

    environment {
        STUDENT_ID = 'FA23-BDS-032'
        IMAGE      = 'ml-api'
        CONTAINER  = 'ml-api'
        NOTIFY_TO  = 'qasimalik@gmail.com'
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 15, unit: 'MINUTES')
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Fetch latest data') {
            steps {
                checkout scm
                sh 'git log -1 --oneline && wc -l dataset/train.csv'
            }
        }

        stage('Set up Python') {
            steps {
                sh '''
                    [ -d venv ] || python3 -m venv venv
                    . venv/bin/activate
                    pip install -q --upgrade pip
                    pip install -q -r requirements.txt pytest
                '''
            }
        }

        stage('Retrain model') {
            steps {
                sh '''
                    . venv/bin/activate
                    rm -rf artifacts
                    GIT_COMMIT=$(git rev-parse HEAD) python train.py
                    cat artifacts/metrics.json
                '''
            }
        }

        stage('Test') {
            steps {
                sh '. venv/bin/activate && python -m pytest -q tests'
            }
        }

        stage('Build Docker image') {
            steps {
                sh 'docker build -t $IMAGE:latest .'
            }
        }

        stage('Deploy on EC2') {
            steps {
                sh '''
                    docker rm -f $CONTAINER || true
                    docker run -d --name $CONTAINER --restart unless-stopped -p 8000:8000 $IMAGE:latest
                    for i in $(seq 1 20); do
                        curl -sf http://localhost:8000/metrics && exit 0
                        sleep 2
                    done
                    echo "API did not come up" && docker logs $CONTAINER && exit 1
                '''
            }
        }
    }

    post {
        always {
            script {
                def m = fileExists('artifacts/metrics.json') ? readFile('artifacts/metrics.json') : 'metrics not available'
                emailext(
                    to: env.NOTIFY_TO,
                    subject: "${env.STUDENT_ID} - MIDTERM build #${env.BUILD_NUMBER}: ${currentBuild.currentResult}",
                    body: """Student Reg No: ${env.STUDENT_ID}
Job: ${env.JOB_NAME} #${env.BUILD_NUMBER}
Result: ${currentBuild.currentResult}
Commit: ${env.GIT_COMMIT}
Build URL: ${env.BUILD_URL}

Metrics:
${m}
"""
                )
            }
            sh 'docker image prune -f || true'
        }
    }
}
