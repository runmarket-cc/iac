# ☁️ RunMarket IaC (Infrastructure as Code)

> **RunMarket 클러스터 인프라 & Helm 차트 통합 관리 저장소**  
> Kubernetes (K3s) 클러스터 기반으로 `RunMarket` 생태계의 모든 마이크로서비스(`web`, `socket`, `batch`, `ollama`), 부하테스트 인프라, 그리고 데이터베이스 백업/복구 시스템(`databasus`)을 코드(IaC)로 선언적으로 관리합니다.

---

## 🏗️ 인프라 아키텍처 (Infrastructure Architecture)

```
                              [Cloudflare CDN & WAF]
                                        │
                         https://api.runmarket.cc (REST)
                         wss://pulse.runmarket.cc (WebSocket)
                         https://databasus.runmarket.cc (Backup Dashboard)
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
│  └────────┬─────────┘        └──────────────────┘                           │
│           │                                                                 │
│           ▼ (Daily Automated Backup & Restore Verification)                 │
│  ┌──────────────────────────────────────────────┐                           │
│  │  databasus (Backup & Restore Verify Daemon)  │                           │
│  │  - Namespace: databasus                      │                           │
│  │  - Daily Restore Verification Test           │                           │
│  └──────────────────────────────────────────────┘                           │
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
| **`helm/databasus`** | DB Backup & Restore | PostgreSQL 일일 자동 백업 및 복구 정합성(Restore Verification) 검증 시스템 | OCI 차트 (`databasus.runmarket.cc`) |

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

# 4. PostgreSQL 백업 및 일일 복구 검증 시스템 (Databasus) 배포
helm install databasus oci://ghcr.io/databasus/charts/databasus \
  -n databasus --create-namespace \
  -f ./helm/databasus/values.yaml
```

---

## 💾 데이터베이스 백업 및 복구 검증 (Database Backup & Disaster Recovery)

데이터 유실 방지 및 재해 복구(DR) 신뢰성을 위해 **Databasus**를 도입하여 자동 백업 및 **일일 복구 검증(Daily Restore Verification)**을 상시 수행합니다.

- **차트 출처**: `oci://ghcr.io/databasus/charts/databasus`
- **배포 네임스페이스**: `databasus`
- **웹 대시보드 콘솔**: `https://databasus.runmarket.cc`
- **핵심 운영 정책**:
  - **Daily Automated Backup**: 매일 정해진 스케줄에 PostgreSQL 데이터베이스의 스냅샷/덤프를 생성하여 안전하게 보관합니다.
  - **Daily Restore Verification**: 단순 백업본 생성에 그치지 않고, 별도의 격리된 환경에서 **매일 자동으로 복구(Restore) 테스트를 수행**하여 백업 데이터의 무결성과 복구 실행 가능성을 보장합니다.
  - **헬스체크 및 무결성 검증**: 복구 프로세스 중 발생할 수 있는 스키마/데이터 불일치를 사전에 감지하고 복구 시간을 추적 관리합니다.

---

## ⚡ 부하테스트 실행 (`runmarket-loadtest`)

부하테스트 관련 시나리오, 파라미터 설정 및 벤치마크 검증 결과는 차트 전용 README인 [`helm/runmarket-loadtest/README.md`](./helm/runmarket-loadtest/README.md)에서 확인하실 수 있습니다.

```bash
# k6 부하테스트 실행
helm install pacer-test ./helm/runmarket-loadtest -n applications

# 부하테스트 진행 로그 확인
kubectl logs -f job/pacer-test-runmarket-loadtest-job -n applications
```
