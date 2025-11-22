# EC2에서 risk-scoring 컨테이너가 unhealthy인 문제 해결

## 문제 상황

배포 후 `trace-x-risk-scoring` 컨테이너가 unhealthy 상태로 표시되어 다른 서비스가 시작되지 않습니다.

## 원인

1. 서버 시작 시간이 오래 걸림
2. healthcheck의 `start_period`가 부족함
3. 서버 시작 중 에러 발생

## 해결 방법

### 1단계: 컨테이너 로그 확인

EC2 서버 터미널에서 다음 명령어로 로그를 확인하세요:

```bash
# 컨테이너 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring

# 또는 실시간 로그 확인
docker-compose -f docker-compose.prod.yml logs -f risk-scoring
```

로그에서 다음을 확인하세요:
- 서버가 정상적으로 시작되는지
- 에러 메시지가 있는지
- 어떤 포트에서 실행되는지

### 2단계: 컨테이너 상태 확인

```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 컨테이너 상세 정보
docker ps -a | grep risk-scoring
```

### 3단계: 컨테이너 내부에서 직접 테스트

```bash
# 컨테이너 내부 접속
docker exec -it trace-x-risk-scoring /bin/bash

# 컨테이너 내부에서 health check
curl http://localhost:5001/health

# 서버 프로세스 확인
ps aux | grep python
```

### 4단계: Healthcheck 설정 조정 (필요 시)

서버 시작 시간이 오래 걸리는 경우, `docker-compose.prod.yml`에서 `start_period`를 늘리거나 healthcheck를 일시적으로 비활성화할 수 있습니다.

#### 옵션 A: start_period 늘리기

`docker-compose.prod.yml`에서:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 120s  # 40s → 120s로 증가
```

#### 옵션 B: Healthcheck 임시 비활성화 (테스트용)

```yaml
# healthcheck:
#   test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
#   interval: 30s
#   timeout: 10s
#   retries: 3
#   start_period: 40s
```

### 5단계: 백엔드 서비스의 depends_on 조건 완화 (임시 해결책)

`docker-compose.prod.yml`에서 `backend` 서비스의 `depends_on` 조건을 완화할 수 있습니다:

```yaml
backend:
  # ... 다른 설정 ...
  depends_on:
    # risk-scoring:
    #   condition: service_healthy
    - risk-scoring  # healthcheck 없이 시작
```

**⚠️ 주의**: 이 경우 `risk-scoring` 서비스가 완전히 시작되기 전에 `backend`가 시작될 수 있습니다.

## 일반적인 문제 및 해결

### 문제 1: 서버 시작 에러

**증상**: 로그에 Python 에러 메시지가 표시됨

**해결**:
- 로그를 확인하여 구체적인 에러 메시지 확인
- 필요한 파일이나 환경 변수가 누락되었는지 확인
- `requirements.txt`의 패키지가 모두 설치되었는지 확인

### 문제 2: 포트 충돌

**증상**: "Address already in use" 에러

**해결**:
```bash
# 포트 사용 중인 프로세스 확인
sudo lsof -i :5001

# 프로세스 종료
sudo kill -9 <PID>
```

### 문제 3: 서버 시작 시간이 너무 김

**증상**: `start_period` 내에 healthcheck가 통과하지 못함

**해결**:
- `start_period`를 120s 이상으로 증가
- 또는 healthcheck를 임시로 비활성화

## 디버깅 명령어

```bash
# 모든 컨테이너 로그 확인
docker-compose -f docker-compose.prod.yml logs

# 특정 컨테이너 로그만 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring

# 컨테이너 재시작
docker-compose -f docker-compose.prod.yml restart risk-scoring

# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 컨테이너 내부 접속
docker exec -it trace-x-risk-scoring /bin/bash

# 서비스 완전히 재시작
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

## 다음 단계

1. **로그 확인**: `docker-compose -f docker-compose.prod.yml logs risk-scoring`
2. **에러 내용 공유**: 로그의 에러 메시지를 확인하고 필요하면 공유
3. **필요 시 수정**: 위의 해결 방법을 적용

로그를 확인한 후 구체적인 에러 메시지를 알려주시면 더 정확한 해결책을 제시할 수 있습니다.

