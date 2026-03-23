#!/bin/bash
# Тестирование метрик

echo "Testing metrics endpoint..."

# Получаем pod
POD=$(kubectl get pods -l app.kubernetes.io/name=latin-square -o jsonpath='{.items[0].metadata.name}')

# Перенаправляем порт
kubectl port-forward $POD 9090:9090 &
PF_PID=$!

sleep 2

# Запрос метрик
echo "Fetching metrics from http://localhost:9090/metrics"
curl -s http://localhost:9090/metrics

# Останавливаем port-forward
kill $PF_PID

echo "✅ Metrics test complete!"