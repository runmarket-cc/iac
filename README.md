# ☁️ RunMarket IaC (Infrastructure as Code)

> **RunMarket 클러스터 인프라 & Helm 차트 통합 관리 저장소**  
> Kubernetes (K3s) 클러스터 기반으로 `RunMarket` 생태계의 모든 마이크로서비스(`web`, `socket`, `batch`, `ollama`)와 부하테스트 인프라를 코드(IaC)로 선언적으로 관리합니다.

---

## 🏗️ 인프라 아키텍처 (Infrastructure Architecture)

```
                              [Cloudflare CDN & WAF]
                                        │
                         https://api.runmarket.cc (REST)
                         wss://pulse.runmarket.cc (WebSocket)
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         K3s Kubernetes Cluster                              │
│                                                                             │
│  [Ingress Controller] Nginx Ingress / Traefik                               │
│           │                                                                 │
│           ├──────────────────────────────┬──────────────────────────────┐   │
│           ▼                              ▼                              ▼   │
│  ┌──────────────────┐        ┌──────────────────┐        ┌──────────────┐   │
│  │  runmarket (web) │        │ runmarket-socket │        │    ollama    │   │
│  │   Spring Boot    │        │  Spring WebFlux  │        │   AI Node    │   │
│  └────────┬─────────┘        └────────┬─────────┘        └──────────────┘   │
│           │                           │                                     │
│           ▼                           ▼                                     │
│  ┌──────────────────┐        ┌──────────────────┐                           │
│  │   PostgreSQL 17  │        │  Redis (Pub/Sub) │                           │
│  └──────────────────┘        └──────────────────┘                           │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ runmarket-loadtest (k6 Load Testing Job)                             │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Helm Charts 구성

| 차트 디렉토리 | 서비스 명 | 상세 설명 | 비고 |
|---|---|---|---|
| **`helm/runmarket`** | REST API & DB | Spring Boot 기반 웹 API (`web`) 및 PostgreSQL 데이터베이스 배포 | `api.runmarket.cc` |
| **`helm/runmarket-socket`** | WebSocket & Redis | Spring WebFlux 고성능 위치 중계 서버 (`socket`) 및 Redis Pub/Sub 배포 | `pulse.runmarket.cc` |
| **`helm/runmarket-batch`** | Batch Crawler | 마라톤 및 대회 데이터 자동 수집 Spring Batch 디몬 | CronJob / Deployment |
| **`helm/runmarket-loadtest`** | k6 Load Test | K3s 내부 서비스 타겟팅 경복궁 둘레길 런 k6 부하테스트 차트 | [상세 가이드](./helm/runmarket-loadtest/README.md) |
| **`helm/ollama`** | AI Inference | Ollama LLM 추론 서버 배포 차트 | NodePort |

---

## 🚀 클러스터 배포 가이드 (Deployment Guide)

### 1. 사전 요구사항 (Prerequisites)
- Kubernetes 클러스터 (K3s / K8s v1.28+)
- Helm v3.0 이상
- `kubectl` CLI 및 적절한 Kubeconfig 접근 권한

### 2. 필수 Kubernetes Secret 구성
애플리케이션 및 DB 접속에 필요한 시크릿을 `applications` 네임스페이스에 미리 생성합니다:

```bash
# 네임스페이스 생성
kubectl create namespace applications

# 1. 앱 및 JWT/인증 시크릿 생성
kubectl create secret generic runmarket-app-secrets \
  --from-literal=jwt-secret=<JWT_SECRET_KEY> \
  --from-literal=mail-password=<MAIL_PASSWORD> \
  --from-literal=admin-email=<ADMIN_EMAIL> \
  --from-literal=admin-password=<ADMIN_PASSWORD> -n applications

# 2. PostgreSQL DB 접속 시크릿 생성
kubectl create secret generic runmarket-db-credentials \
  --from-literal=username=<DB_USERNAME> \
  --from-literal=password=<DB_PASSWORD> \
  --from-literal=database=<DB_NAME> -n applications
```

### 3. Helm 차트 배포 순서

```bash
# 1. 메인 REST API 및 PostgreSQL 배포
helm install runmarket ./helm/runmarket -n applications

# 2. WebSocket 중계 서버 및 Redis 배포
helm install runmarket-socket ./helm/runmarket-socket -n applications

# 3. 배치 크롤러 배포 (필요 시)
helm install runmarket-batch ./helm/runmarket-batch -n applications
```

---

## ⚡ 부하테스트 실행 (`runmarket-loadtest`)

부하테스트 관련 시나리오, 파라미터 설정 및 벤치마크 검증 결과는 차트 전용 README인 [`helm/runmarket-loadtest/README.md`](./helm/runmarket-loadtest/README.md)에서 확인하실 수 있습니다.

```bash
# k6 부하테스트 실행
helm install pacer-test ./helm/runmarket-loadtest -n applications

# 부하테스트 진행 로그 확인
kubectl logs -f job/pacer-test-runmarket-loadtest-job -n applications
```