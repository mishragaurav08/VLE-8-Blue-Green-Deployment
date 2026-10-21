pipeline {
    agent any

    parameters {
        choice(
            name: 'TARGET_COLOR',
            choices: ['green', 'blue'],
            description: 'Environment to deploy and route traffic to'
        )
    }

    stages {
        stage('Checkout GitHub') {
            steps {
                deleteDir()
                git branch: 'main',
                    url: 'https://github.com/mishragaurav08/VLE-8-Blue-Green-Deployment.git'
            }
        }

        stage('Validate Manifests') {
            steps {
                sh '''
                    set -eu
                    test -f deployment-blue.yaml
                    test -f deployment-green.yaml
                    test -f service.yaml
                    echo "Kubernetes manifests found."
                '''
            }
        }

        stage('Deploy Target Environment') {
            steps {
                withCredentials([
                    string(credentialsId: 'k8s-deployer-token',
                           variable: 'K8S_TOKEN')
                ]) {
                    sh '''
                        set +x
                        set -eu

                        if [ "$TARGET_COLOR" = "green" ]; then
                            DEPLOYMENT="myapp-green"
                        else
                            DEPLOYMENT="myapp-blue"
                        fi

                        kubectl --server=https://172.31.18.169:6443 \
                          --certificate-authority=/etc/jenkins/kubernetes/server-ca.crt \
                          --token="$K8S_TOKEN" \
                          apply -f "deployment-${TARGET_COLOR}.yaml"

                        kubectl --server=https://172.31.18.169:6443 \
                          --certificate-authority=/etc/jenkins/kubernetes/server-ca.crt \
                          --token="$K8S_TOKEN" \
                          rollout status "deployment/$DEPLOYMENT" \
                          --timeout=90s
                    '''
                }
            }
        }

        stage('Switch Traffic and Verify') {
            steps {
                withCredentials([
                    string(credentialsId: 'k8s-deployer-token',
                           variable: 'K8S_TOKEN')
                ]) {
                    sh '''
                        set +x
                        set -eu

                        API="https://172.31.18.169:6443"
                        CA="/etc/jenkins/kubernetes/server-ca.crt"

                        kubectl --server="$API" --certificate-authority="$CA" \
                          --token="$K8S_TOKEN" \
                          patch service myapp-service \
                          -p "{\\"spec\\":{\\"selector\\":{\\"app\\":\\"myapp\\",\\"color\\":\\"${TARGET_COLOR}\\"}}}"

                        if kubectl --server="$API" --certificate-authority="$CA" \
                          --token="$K8S_TOKEN" \
                          get endpoints myapp-service -o jsonpath='{.subsets[*].addresses[*].ip}' \
                          | grep -q .; then
                            echo "SUCCESS: Service has a ready endpoint for ${TARGET_COLOR}."
                        else
                            echo "ERROR: No ready endpoint. Rolling back to Blue."
                            kubectl --server="$API" --certificate-authority="$CA" \
                              --token="$K8S_TOKEN" \
                              patch service myapp-service \
                              -p '{"spec":{"selector":{"app":"myapp","color":"blue"}}}'
                            exit 1
                        fi
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed. Check the Console Output and current Service selector.'
        }
        success {
            echo 'Blue-Green deployment completed successfully.'
        }
    }
}
