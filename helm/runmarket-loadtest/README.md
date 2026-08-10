# Runmarket Pacer k6 Load Testing Chart

Runmarket `pacer` 서비스 (REST API & WebSocket) 부하테스트를 위한 Helm 차트입니다.

## 주요 기능

1. **K3s 내부 Service (`svc`) 주소 부하테스트 (기본값)**: Cloudflare 및 Ingress 영향을 배제한 백엔드 (Spring Boot, DB, Redis) 순수 수용량 측정
2. **외부 공용 도메인 (`https://api.runmarket.cc`) 부하테스트**: `values.yaml` 오버라이드를 통해 E2E 경로 검증 지원
3. **수동 트리거 방식**: 안전한 트리거를 위해 필요할 때만 `helm install`로 Kubernetes Job 실행

## 부하테스트 실행 방법 (수동 트리거)

### 1. K3s 내부 서비스 주소 타겟팅 (기본 1단계 테스트)
```bash
helm install pacer-test ./helm/runmarket-loadtest
```

### 2. 가상 유저(VUs) 및 지속시간 오버라이드 실행
```bash
helm install pacer-test ./helm/runmarket-loadtest \
  --set loadProfile.vus=100 \
  --set loadProfile.duration=5m
```

### 3. 외부 공용 도메인 타겟팅 (Cloudflare WAF Allowlist 사전 세팅 필수)
```bash
helm install pacer-test ./helm/runmarket-loadtest \
  --set target.apiBaseUrl="https://api.runmarket.cc" \
  --set target.wsBaseUrl="wss://pulse.runmarket.cc" \
  --set loadProfile.vus=50
```

### 4. 테스트 결과 확인 및 삭제
```bash
# k6 부하테스트 로그 확인
kubectl logs -f job/pacer-test-runmarket-loadtest-job

# 테스트 완료 후 Helm 릴리스 정리
helm uninstall pacer-test
```

## 보안 가이드 (Security Guidelines)

- **비밀값 분리**: API 인증 토큰이나 비밀번호는 차트 내부에 저장하지 않으며, 필요 시 Kubernetes Secret 또는 `--set` 옵션으로 실행 시 주입합니다.
- **WAF 방어**: 외부 URL 타겟팅 테스트 시에는 Cloudflare 대시보드에서 테스터 IP를 Allowlist 처리하여 제3자의 무단 대량 부하 요청 차단 정책을 유지합니다.
