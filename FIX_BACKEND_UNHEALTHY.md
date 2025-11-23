# Backend가 Unhealthy 상태인 문제 해결

## 현재 상황

- ✅ `risk-scoring`: **healthy** (정상)
- ❌ `backend`: **unhealthy** (문제)
- ✅ `risk-scoring` healthcheck: 정상 응답 (`{"status": "ok"}`)

## 원인

`backend`의 healthcheck가 실패하고 있습니다. healthcheck는 `/api/dashboard/summary` 엔드포인트를 확인하는데, 이 엔드포인트가 응답하지 않거나 에러를 반환하고 있을 가능성이 높습니다.

## 해결 방법

### 1단계: Backend 로그 확인 (가장 중요!)

EC2 서버에서 다음 명령어를 실행하세요:

```bash
cd ~/trace-x

# backend 로그 확인
docker-compose -f docker-compose.prod.yml logs backend | tail -100

# 또는 실시간 로그 확인
docker-compose -f docker-compose.prod.yml logs -f backend
```

**확인할 내용:**
- 서버가 정상적으로 시작되는지
- 에러 메시지가 있는지
- `/api/dashboard/summary` 엔드포인트가 존재하는지

### 2단계: Backend Healthcheck 직접 테스트

```bash
# backend healthcheck 엔드포인트 직접 테스트
curl http://localhost:8888/api/dashboard/summary

# 또는 간단한 엔드포인트 테스트
curl http://localhost:8888/

# backend가 실행 중인지 확인
curl http://localhost:8888/health  # health 엔드포인트가 있다면
```

**예상 결과:**
- 정상: JSON 응답 또는 200 상태 코드
- 에러: 404, 500, 또는 연결 실패

### 3단계: Backend 컨테이너 내부 확인

```bash
# backend 컨테이너 내부 접속
docker exec -it trace-x-backend /bin/bash

# 컨테이너 내부에서:
curl http://localhost:8888/api/dashboard/summary

# 서버 프로세스 확인
ps aux | grep python

# 환경 변수 확인
env | grep -E "ETHERSCAN|FLASK|API"
```

### 4단계: Healthcheck 엔드포인트 변경 (임시 해결)

`/api/dashboard/summary`가 문제가 있다면, 더 간단한 엔드포인트로 healthcheck를 변경할 수 있습니다:

```yaml
backend:
  # ... 다른 설정 ...
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8888/health"]  # 또는 "/" 또는 다른 엔드포인트
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s  # 40s에서 60s로 증가
```

---

## 빠른 해결 방법 (권장)

EC2 서버에서 다음 명령어를 순서대로 실행하세요:

### 방법 A: 로그 확인 후 해결

```bash
cd ~/trace-x

# 1. backend 로그 확인 (에러 찾기)
docker-compose -f docker-compose.prod.yml logs backend | tail -100

# 2. backend healthcheck 직접 테스트
curl -v http://localhost:8888/api/dashboard/summary

# 3. 에러 내용에 따라 해결
# - 404 에러: 엔드포인트가 없음 → healthcheck 엔드포인트 변경
# - 500 에러: 서버 내부 에러 → 로그에서 원인 확인
# - 연결 실패: 서버가 시작되지 않음 → 로그 확인
```

### 방법 B: Healthcheck 임시 비활성화 (테스트용)

`docker-compose.prod.yml`에서 `backend`의 healthcheck를 주석 처리:

```yaml
backend:
  # ... 다른 설정 ...
  # healthcheck:
  #   test: ["CMD", "curl", "-f", "http://localhost:8888/api/dashboard/summary"]
  #   interval: 30s
  #   timeout: 10s
  #   retries: 3
  #   start_period: 40s
```

그리고 `frontend`의 `depends_on` 조건도 수정:

```yaml
frontend:
  # ... 다른 설정 ...
  depends_on:
    - backend  # condition: service_healthy 제거
  # ... 나머지 설정 ...
```

---

## 일반적인 문제 및 해결

### 문제 1: 404 Not Found

**증상**: `curl http://localhost:8888/api/dashboard/summary` → 404

**원인**: 엔드포인트가 존재하지 않음

**해결**:
1. 다른 엔드포인트로 healthcheck 변경 (예: `/health`, `/`, `/api/health`)
2. 또는 해당 엔드포인트를 백엔드에 추가

### 문제 2: 500 Internal Server Error

**증상**: `curl http://localhost:8888/api/dashboard/summary` → 500

**원인**: 서버 내부 에러 (데이터베이스 연결 실패, 환경 변수 누락 등)

**해결**:
- 로그에서 구체적인 에러 메시지 확인
- 환경 변수 확인 (`.env` 파일)
- 필요한 서비스가 실행 중인지 확인

### 문제 3: 연결 실패 (Connection refused)

**증상**: `curl http://localhost:8888/api/dashboard/summary` → 연결 실패

**원인**: 서버가 시작되지 않음

**해결**:
- 로그 확인: `docker-compose logs backend`
- 서버 시작 에러 확인
- 포트 충돌 확인: `sudo lsof -i :8888`

### 문제 4: ETHERSCAN_API_KEY 누락

**증상**: 로그에 API 키 관련 에러

**해결**:
```bash
# .env 파일 확인
cat ~/trace-x/.env | grep ETHERSCAN

# .env 파일 수정
nano ~/trace-x/.env
# ETHERSCAN_API_KEY=실제_키_입력

# 컨테이너 재시작
docker-compose -f docker-compose.prod.yml restart backend
```

---

## 즉시 실행할 명령어

```bash
cd ~/trace-x

# 1. backend 로그 확인 (가장 중요!)
docker-compose -f docker-compose.prod.yml logs backend | tail -100

# 2. healthcheck 직접 테스트
curl -v http://localhost:8888/api/dashboard/summary

# 3. 간단한 엔드포인트 테스트
curl http://localhost:8888/

# 4. 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 5. backend 재시작
docker-compose -f docker-compose.prod.yml restart backend

# 6. 10초 후 상태 확인
sleep 10
docker-compose -f docker-compose.prod.yml ps
```

---

## 확인 사항

### 1. Backend 로그 확인

```bash
docker-compose -f docker-compose.prod.yml logs backend | grep -i error
docker-compose -f docker-compose.prod.yml logs backend | grep -i exception
docker-compose -f docker-compose.prod.yml logs backend | grep -i failed
```

### 2. Healthcheck 엔드포인트 확인

```bash
# 다양한 엔드포인트 테스트
curl http://localhost:8888/
curl http://localhost:8888/health
curl http://localhost:8888/api/dashboard/summary
curl http://localhost:8888/api/health
```

### 3. 환경 변수 확인

```bash
# .env 파일 확인
cat ~/trace-x/.env

# 컨테이너 내부 환경 변수 확인
docker exec trace-x-backend env | grep -E "ETHERSCAN|FLASK|API"
```

---

## 다음 단계

1. **로그 확인**: `docker-compose logs backend` - 에러 메시지 확인
2. **Healthcheck 테스트**: `curl http://localhost:8888/api/dashboard/summary` - 응답 확인
3. **에러 내용 공유**: 로그와 curl 결과를 확인하여 구체적인 문제 파악
4. **해결 방법 적용**: 위의 해결 방법 중 적절한 것 선택

---

**가장 먼저 할 일**: `docker-compose -f docker-compose.prod.yml logs backend` 로그를 확인하세요! 🔍

