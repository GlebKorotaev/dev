#!/bin/bash
set -euo pipefail

echo "=== Deploying Latin Square to Kubernetes ==="

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl"
    exit 1
fi

# Проверка подключения к кластеру
if ! kubectl cluster-info &> /dev/null; then
    echo "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Установка с помощью Helm
echo "Installing with Helm..."
helm upgrade --install latin-square ./helm/latin-square \
  --namespace default \
  --set image.repository=gleb332/dev2 \
  --set image.tag=latest

# Проверка развертывания
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/latin-square --timeout=120s

# Получение информации о сервисах
echo "Services:"
kubectl get svc latin-square

echo "Pods:"
kubectl get pods -l app.kubernetes.io/name=latin-square

echo "✅ Deployment complete!"