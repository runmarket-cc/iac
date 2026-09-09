#!/usr/bin/env bash
set -euo pipefail

# Databasus 배포 스크립트
# RunMarket PostgreSQL 일일 자동 백업 및 복구 검증(Restore Verification) 시스템

NAMESPACE="databasus"
CHART_OCI="oci://ghcr.io/databasus/charts/databasus"
VALUES_FILE="./helm/databasus/values.yaml"

echo "==> Deploying Databasus to namespace: ${NAMESPACE}"

# 1. 네임스페이스 생성 (없는 경우)
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# 2. Helm OCI 차트 설치 또는 업그레이드
if [ -f "${VALUES_FILE}" ]; then
  helm upgrade --install databasus "${CHART_OCI}" \
    --namespace "${NAMESPACE}" \
    -f "${VALUES_FILE}"
else
  helm upgrade --install databasus "${CHART_OCI}" \
    --namespace "${NAMESPACE}"
fi

echo "==> Databasus deployment completed successfully!"
