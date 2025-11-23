# 문제 해결 가이드

이 문서는 배포 및 실행 중 발생할 수 있는 문제들을 해결하는 방법을 정리한 것입니다.

## 목차

- [디스크 공간 부족](#디스크-공간-부족)
- [Python 버전 문제](#python-버전-문제)
- [의존성 모듈 누락](#의존성-모듈-누락)
- [Healthcheck 실패](#healthcheck-실패)
- [컨테이너 로그 확인](#컨테이너-로그-확인)

---

## 디스크 공간 부족

### 증상

```
no space left on device
```

### 해결 방법

```bash
# Docker 정리 (가장 빠른 방법)
docker system prune -a --volumes

# 확인 메시지 나오면 'y' 입력

# 디스크 공간 확인
df -h
```

---

## Python 버전 문제

### 증상

```
ERROR: Could not find a version that satisfies the requirement networkx>=3.3
```

### 원인

`networkx>=3.3`은 Python 3.10+가 필요합니다.

### 해결 방법

```bash
cd ~/trace-x/risk-scoring

# 최신 코드 가져오기
git pull origin main

# Dockerfile 확인 (python:3.10-slim이어야 함)
head -1 Dockerfile

# 캐시 없이 재빌드
cd ..
docker-compose -f docker-compose.prod.yml build --no-cache risk-scoring
```

---

## 의존성 모듈 누락

### 증상

```
ModuleNotFoundError: No module named 'sklearn'
```

### 해결 방법

```bash
cd ~/trace-x/risk-scoring

# 최신 코드 가져오기
git pull origin main

# requirements.txt 확인
grep scikit-learn requirements.txt

# 캐시 없이 재빌드
cd ..
docker-compose -f docker-compose.prod.yml build --no-cache risk-scoring
```

---

## Healthcheck 실패

### Backend가 Unhealthy 상태

#### 증상

```bash
docker-compose -f docker-compose.prod.yml ps
# trace-x-backend         Up X minutes (unhealthy)
```

#### 해결 방법

1. **Backend에 `/health` 엔드포인트 추가**

```bash
cd ~/trace-x/backend

# src/app.py 파일 편집
nano src/app.py
```

`app.analyzer = Analyzer(api_key=api_key)` 바로 다음에 추가:

```python
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Docker healthcheck"""
    return jsonify({'status': 'ok', 'service': 'trace-x-backend'}), 200
```

2. **Backend 재빌드**

```bash
cd ~/trace-x
docker-compose -f docker-compose.prod.yml build --no-cache backend
docker-compose -f docker-compose.prod.yml up -d
```

### Risk-scoring이 Unhealthy 상태

#### 해결 방법

```bash
# 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring

# Healthcheck 직접 테스트
curl http://localhost:5001/health

# 컨테이너 재시작
docker-compose -f docker-compose.prod.yml restart risk-scoring
```

---

## 컨테이너 로그 확인

### 모든 서비스 로그

```bash
docker-compose -f docker-compose.prod.yml logs
```

### 특정 서비스 로그

```bash
# Risk-scoring
docker-compose -f docker-compose.prod.yml logs risk-scoring

# Backend
docker-compose -f docker-compose.prod.yml logs backend

# Frontend
docker-compose -f docker-compose.prod.yml logs frontend
```

### 실시간 로그 확인

```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### 에러 검색

```bash
docker-compose -f docker-compose.prod.yml logs | grep -i error
docker-compose -f docker-compose.prod.yml logs | grep -i exception
docker-compose -f docker-compose.prod.yml logs | grep -i failed
```

---

## 컨테이너 상태 확인

```bash
# 모든 컨테이너 상태
docker-compose -f docker-compose.prod.yml ps

# 상세 정보
docker ps -a | grep trace-x
```

---

## 서비스 재시작

```bash
# 특정 서비스 재시작
docker-compose -f docker-compose.prod.yml restart risk-scoring

# 모든 서비스 재시작
docker-compose -f docker-compose.prod.yml restart

# 완전히 재시작 (중지 후 시작)
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

---

## 네트워크 문제

### 컨테이너 간 통신 실패

```bash
# 네트워크 확인
docker network inspect trace-x_trace-x-network

# 컨테이너가 네트워크에 연결되어 있는지 확인
docker network inspect trace-x_trace-x-network | grep -A 5 risk-scoring
```

---

## 포트 충돌

### 증상

```
Address already in use
```

### 해결 방법

```bash
# 포트 사용 중인 프로세스 확인
sudo lsof -i :5001
sudo lsof -i :8888
sudo lsof -i :5173

# 프로세스 종료
sudo kill -9 <PID>
```

---

## 추가 도움말

더 자세한 내용은 다음 문서를 참고하세요:

- [빠른 배포 가이드](./QUICK_DEPLOY.md)
- [전체 배포 가이드](./docs/DEPLOYMENT.md)
- [백엔드 팀 전달 문서](./BACKEND_TEAM_HANDOFF.md)

