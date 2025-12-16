pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'ENABLE_PORT_FORWARD',
            defaultValue: false,
            description: 'Enable port-forwarding for services after deployment'
        )
        string(
            name: 'MINIKUBE_PROFILE',
            defaultValue: 'minikube',
            description: 'Minikube profile name'
        )
        choice(
            name: 'TERRAFORM_WORKSPACE',
            choices: ['local'],
            description: 'Terraform workspace to use'
        )
    }

    environment {
        PROJECT_ROOT = "${WORKSPACE}"
        TERRAFORM_DIR = "${WORKSPACE}/terraform/${params.TERRAFORM_WORKSPACE}"
        MINIKUBE_PROFILE = "${params.MINIKUBE_PROFILE}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 1: Checking out code from GitHub"
                    echo "=========================================="
                }
                checkout scm
                sh '''
                    echo "Repository checked out successfully"
                    echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
                    echo "Latest commit: $(git rev-parse --short HEAD)"
                '''
            }
        }

        stage('Ensure Minikube is Running') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 2: Ensuring Minikube is running"
                    echo "=========================================="
                }
                sh '''
                    # Check if minikube command is available
                    if command -v minikube >/dev/null 2>&1; then
                        # Check if Minikube is running
                        if minikube status -p ${MINIKUBE_PROFILE} 2>/dev/null | grep -q "Running"; then
                            echo "✓ Minikube is already running"
                        else
                            echo "Minikube is not running. Starting Minikube..."
                            minikube start -p ${MINIKUBE_PROFILE} || {
                                echo "Failed to start Minikube"
                                exit 1
                            }
                            echo "✓ Minikube started successfully"
                        fi
                        
                        # Get Minikube IP
                        MINIKUBE_IP=$(minikube ip -p ${MINIKUBE_PROFILE} 2>/dev/null || echo "")
                        if [ -n "$MINIKUBE_IP" ]; then
                            echo "Minikube IP: ${MINIKUBE_IP}"
                        fi
                    else
                        echo "⚠ minikube command not available (Jenkins may be running inside Kubernetes)"
                        echo "Assuming cluster is already accessible via kubectl"
                        
                        # Verify kubectl can access the cluster
                        if kubectl cluster-info >/dev/null 2>&1; then
                            echo "✓ Kubernetes cluster is accessible"
                            CLUSTER_INFO=$(kubectl cluster-info | head -n 1)
                            echo "Cluster: ${CLUSTER_INFO}"
                        else
                            echo "ERROR: Cannot access Kubernetes cluster"
                            exit 1
                        fi
                    fi
                '''
            }
        }

        stage('Point Docker to Minikube') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 3: Pointing Docker to Minikube"
                    echo "=========================================="
                }
                sh '''
                    # Check if minikube command is available
                    if command -v minikube >/dev/null 2>&1; then
                        # Configure Docker to use Minikube's Docker daemon
                        eval $(minikube -p ${MINIKUBE_PROFILE} docker-env)
                        
                        # Verify Docker is pointing to Minikube
                        DOCKER_HOST=$(echo $DOCKER_HOST)
                        echo "Docker Host: ${DOCKER_HOST}"
                        
                        if [ -z "$DOCKER_HOST" ]; then
                            echo "ERROR: DOCKER_HOST is not set"
                            exit 1
                        fi
                        
                        echo "✓ Docker is now pointing to Minikube"
                    else
                        echo "⚠ minikube command not available"
                        echo "Assuming Docker is already configured (Jenkins may be using host Docker socket)"
                    fi
                    
                    # Test Docker connection
                    docker ps > /dev/null 2>&1 || {
                        echo "ERROR: Cannot connect to Docker daemon"
                        exit 1
                    }
                    echo "✓ Docker connection verified"
                '''
            }
        }

        stage('Build All Service Images') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 4: Building all service images"
                    echo "=========================================="
                }
                sh '''
                    # Ensure Docker is still pointing to Minikube (if minikube is available)
                    if command -v minikube >/dev/null 2>&1; then
                        eval $(minikube -p ${MINIKUBE_PROFILE} docker-env)
                    fi
                    
                    # List of services to build
                    SERVICES=("stack" "linkedlist" "graph" "backend" "ui")
                    
                    for service in "${SERVICES[@]}"; do
                        if [ -f "${PROJECT_ROOT}/${service}/Dockerfile" ]; then
                            echo "Building ${service}-service:latest..."
                            docker build -t ${service}-service:latest ${PROJECT_ROOT}/${service}/ || {
                                echo "ERROR: Failed to build ${service}-service"
                                exit 1
                            }
                            echo "✓ Successfully built ${service}-service:latest"
                        else
                            echo "WARNING: Dockerfile not found for ${service}"
                        fi
                    done
                    
                    echo ""
                    echo "All images built successfully:"
                    docker images | grep -E "(stack-service|linkedlist-service|graph-service|backend-service|ui-service)" || true
                '''
            }
        }

        stage('Terraform Init + Apply') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 5: Running Terraform init + apply"
                    echo "=========================================="
                }
                sh '''
                    # Ensure kubectl context is set to Minikube
                    kubectl config use-context ${MINIKUBE_PROFILE} || {
                        echo "WARNING: Could not set kubectl context, continuing..."
                    }
                    
                    cd ${TERRAFORM_DIR}
                    
                    echo "Running terraform init..."
                    terraform init || {
                        echo "ERROR: Terraform init failed"
                        exit 1
                    }
                    echo "✓ Terraform initialized"
                    
                    echo ""
                    echo "Running terraform apply..."
                    terraform apply -auto-approve || {
                        echo "ERROR: Terraform apply failed"
                        exit 1
                    }
                    echo "✓ Terraform apply completed successfully"
                '''
            }
        }

        stage('Verify Pods & Services') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 6: Verifying pods and services"
                    echo "=========================================="
                }
                sh '''
                    # Wait for pods to be ready
                    echo "Waiting for pods to be ready..."
                    MAX_RETRIES=40
                    RETRY_COUNT=0
                    
                    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                        # Get pod status
                        PODS=$(kubectl get pods --no-headers 2>/dev/null)
                        
                        if [ -z "$PODS" ]; then
                            echo "No pods found yet, waiting..."
                            sleep 5
                            RETRY_COUNT=$((RETRY_COUNT + 1))
                            continue
                        fi
                        
                        # Count pods that are not Running
                        NOT_READY=$(echo "$PODS" | grep -v "Running" | grep -v "Completed" | wc -l | tr -d ' ')
                        
                        if [ "$NOT_READY" -eq 0 ] && [ -n "$PODS" ]; then
                            echo "✓ All pods are Running!"
                            break
                        fi
                        
                        if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
                            echo "Still waiting for pods... (attempt $RETRY_COUNT/$MAX_RETRIES)"
                            kubectl get pods || true
                        fi
                        
                        sleep 3
                        RETRY_COUNT=$((RETRY_COUNT + 1))
                    done
                    
                    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
                        echo "WARNING: Timeout waiting for pods. Current status:"
                        kubectl get pods || true
                    fi
                    
                    echo ""
                    echo "=== Pod Status ==="
                    kubectl get pods || true
                    
                    echo ""
                    echo "=== Service Status ==="
                    kubectl get services || true
                    
                    echo ""
                    echo "=== Deployment Status ==="
                    kubectl get deployments || true
                    
                    # Get cluster IP for access URLs
                    if command -v minikube >/dev/null 2>&1; then
                        MINIKUBE_IP=$(minikube ip -p ${MINIKUBE_PROFILE} 2>/dev/null || echo "unknown")
                    else
                        # Try to get node IP from Kubernetes
                        MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "unknown")
                    fi
                    echo ""
                    echo "=========================================="
                    echo "Access URLs:"
                    echo "=========================================="
                    echo "Web UI:      http://${MINIKUBE_IP}:32080/"
                    echo "Backend API: http://${MINIKUBE_IP}:32080/api/dashboard"
                    if command -v minikube >/dev/null 2>&1; then
                        echo "Jenkins:     http://${MINIKUBE_IP}:32081 (if Jenkins is deployed)"
                    else
                        echo "Jenkins:     Check service NodePort for access"
                    fi
                    echo ""
                '''
            }
        }

        stage('Optional Port-Forward') {
            when {
                expression { 
                    return params.ENABLE_PORT_FORWARD.toBoolean()
                }
            }
            steps {
                script {
                    echo "=========================================="
                    echo "Stage 7: Setting up port-forward (Optional)"
                    echo "=========================================="
                }
                sh '''
                    echo "Port-forward is enabled. Setting up port-forwards..."
                    echo "Note: Port-forwards run in background and will be active until pipeline completes"
                    
                    # Port-forward UI service
                    kubectl port-forward svc/ui-service 8080:80 &
                    echo "✓ UI service port-forward: http://localhost:8080"
                    
                    # Port-forward Backend service
                    kubectl port-forward svc/backend-service 5000:5000 &
                    echo "✓ Backend service port-forward: http://localhost:5000"
                    
                    # Port-forward Jenkins service (if exists)
                    kubectl port-forward svc/jenkins-service 8081:8080 2>/dev/null &
                    echo "✓ Jenkins service port-forward: http://localhost:8081 (if available)"
                    
                    echo ""
                    echo "Port-forwards are running. Access services at:"
                    echo "  - UI:      http://localhost:8080"
                    echo "  - Backend: http://localhost:5000"
                    echo "  - Jenkins: http://localhost:8081"
                '''
            }
        }
    }

    post {
        success {
            echo "=========================================="
            echo "Pipeline completed successfully! ✓"
            echo "=========================================="
        }
        failure {
            echo "=========================================="
            echo "Pipeline failed! ✗"
            echo "=========================================="
            sh '''
                echo "Debugging information:"
                echo ""
                echo "=== Pod Status ==="
                kubectl get pods || true
                echo ""
                echo "=== Pod Logs (last 20 lines) ==="
                for pod in $(kubectl get pods -o jsonpath='{.items[*].metadata.name}'); do
                    echo "--- Logs for $pod ---"
                    kubectl logs --tail=20 $pod || true
                done
            '''
        }
        always {
            echo "Pipeline execution completed."
        }
    }
}

