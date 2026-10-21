pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/mishragaurav08/VLE-8-Blue-Green-Deployment.git'
            }
        }

        stage('Validate Kubernetes Manifests') {
            steps {
                sh '''
                    kubectl apply --dry-run=client -f deployment-blue.yaml
                    kubectl apply --dry-run=client -f deployment-green.yaml
                    kubectl apply --dry-run=client -f service.yaml
                '''
            }
        }

        stage('Verify Kubernetes Access') {
            steps {
                withCredentials([
                    string(credentialsId: 'k8s-deployer-token',
                           variable: 'K8S_TOKEN')
                ]) {
                    sh '''
                        set +x
                        HTTP_CODE=$(curl --connect-timeout 5 \
                          --cacert /etc/jenkins/kubernetes/server-ca.crt \
                          -sS -o /dev/null -w '%{http_code}' \
                          -H "Authorization: Bearer ${K8S_TOKEN}" \
                          https://172.31.18.169:6443/api/v1/namespaces/default/services/myapp-service)

                        echo "Kubernetes API HTTP status: ${HTTP_CODE}"
                        test "$HTTP_CODE" = "200"
                    '''
                }
            }
        }
    }
}
