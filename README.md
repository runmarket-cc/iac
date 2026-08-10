# ☁️ RunMarket IaC (Infrastructure as Code)

RunMarket 서비스의 Kubernetes(K3s) 클러스터 배포 및 인프라를 위한 Helm Chart 및 배포 관리 저장소입니다.

---

## 📁 Helm Charts 구성

```
iac/
└── helm/
    ├── runmarket/            # Spring Boot REST API & PostgreSQL 메인 차트
    ├── runmarket-socket/     # WebFlux 기반 WebSocket 중계 서버 & Redis 차트
    ├── runmarket-batch/      # 마라톤/레이스 대회 수집 배치 차트
    └── runmarket-loadtest/   # [신규] k6 기반 경복궁 둘레길 런 부하테스트 차트
```

---

## ⚡ 부하테스트 및 성능 검증 결과 (Load Test Benchmark)

`runmarket-loadtest` 차트를 사용하여 K3s 클러스터 내부 백엔드(`runmarket`, `runmarket-socket`) 및 Redis, PostgreSQL 수용량을 검증하였습니다.

### 🏃 경복궁 둘레길 1,000명 동시 런 테스트 결과
* **테스트 컨셉**: 경복궁 둘레길(약 2.4km)을 1,000명의 러너가 시계방향/반시계방향으로 1초 간격 실시간 GPS 좌표를 전송하는 시뮬레이션
* **Ramp-Up 시나리오**: 10초당 100명씩 서서히 증대 (`1m30s`) ➔ 1,000명 피크 상태 2분간 유지 (`2m`)
* **최대 동시 접속자 수**: `1,000 VUs` (Virtual Users)
* **성공률**: **100.00%** (소켓 토큰 발급 HTTP 200 & WebSocket 101 Handshake 전량 성공)
* **에러율**: **0.00%**
* **Redis 상태**: RDB BGSAVE 백그라운드 디스크 저장 100% 성공 (`terminated with success`)

---

## 🚀 부하테스트 실행 명령어

```bash
# 부하테스트 실행 (applications 네임스페이스)
helm install pacer-test ./helm/runmarket-loadtest -n applications

# 실시간 모니터링 로그 확인
kubectl logs -f job/pacer-test-runmarket-loadtest-job -n applications

# 테스트 종료 후 정리
helm uninstall pacer-test -n applications
```