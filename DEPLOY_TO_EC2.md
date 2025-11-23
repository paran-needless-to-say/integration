# EC2 서버에 리스크 스코어링 API 배포하기

## 백엔드 팀 요청사항

> "로컬 말고 실제 서버 열어서 하라"

**의미**: 개발자의 컴퓨터(로컬)가 아닌 **EC2 서버**에서 리스크 스코어링 API를 실행해야 합니다.

---

## 현재 상황

### ✅ 완료된 것

- 리스크 스코어링 API 구현 완료
- Docker 이미지 빌드 성공
- Docker Compose 설정 완료
- 모든 배포 문제 해결

### ⚠️ 확인 필요

EC2 서버에서 실제로 배포가 완료되었는지 확인이 필요합니다.

---

## EC2 서버 배포 방법

### 1단계: EC2 서버 접속

```bash
# 로컬 터미널에서
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@<EC2-PUBLIC-IP>
```

**EC2 Public IP 확인**: AWS 콘솔 → EC2 → 인스턴스 → 퍼블릭 IPv4 주소

### 2단계: 프로젝트 클론 또는 업데이트

```bash
# EC2 서버에 접속한 후
cd ~

# 이미 클론되어 있다면
cd trace-x
git pull origin main

# 처음이라면
git clone https://github.com/paran-needless-to-say/integration.git trace-x
cd trace-x
```

### 3단계: 서브디렉토리 설정 (중요!)

`risk-scoring`, `frontend`, `backend` 디렉토리가 비어있을 수 있습니다. 다음 스크립트로 설정:

```bash
# 자동 설정 스크립트 실행
chmod +x scripts/setup-subdirectories.sh
./scripts/setup-subdirectories.sh
```

또는 수동으로:

```bash
# risk-scoring 클론
rm -rf risk-scoring
git clone https://github.com/paran-needless-to-say/aml-risk-engine2.git risk-scoring

# frontend 클론
rm -rf frontend
git clone https://github.com/paran-needless-to-say/frontend.git frontend

# backend 클론
rm -rf backend
git clone https://github.com/paran-needless-to-say/100end.git backend
```

### 4단계: 환경 변수 설정

```bash
# .env 파일 생성 또는 수정
nano .env
```

다음 내용 추가:

```bash
ETHERSCAN_API_KEY=실제_키_입력
FLASK_ENV=production
PYTHONUNBUFFERED=1
VITE_BACKEND_API_URL=http://<EC2-PUBLIC-IP>:8888
RISK_SCORING_API_URL=http://risk-scoring:5001
```

**⚠️ 중요**: `RISK_SCORING_API_URL=http://risk-scoring:5001` (Docker Compose 내부 네트워크)

### 5단계: 배포 실행

```bash
# 배포 스크립트 실행
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

또는 수동으로:

```bash
# 기존 컨테이너 중지
docker-compose -f docker-compose.prod.yml down

# 이미지 빌드 및 시작
docker-compose -f docker-compose.prod.yml up -d --build

# 상태 확인
docker-compose -f docker-compose.prod.yml ps
```

### 6단계: 배포 확인

```bash
# 리스크 스코어링 API healthcheck
curl http://localhost:5001/health

# 예상 응답:
# {"status": "ok", "service": "aml-risk-engine"}

# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring
```

---

## 배포 성공 확인

### ✅ 성공한 경우

```bash
$ docker-compose -f docker-compose.prod.yml ps

NAME                      STATUS
trace-x-risk-scoring      Up X minutes (healthy)
trace-x-backend          Up X minutes (healthy)
trace-x-frontend         Up X minutes (healthy)
```

```bash
$ curl http://localhost:5001/health

{"status": "ok", "service": "aml-risk-engine"}
```

### ❌ 실패한 경우

로그를 확인하세요:

```bash
docker-compose -f docker-compose.prod.yml logs risk-scoring
```

문제 해결은 `TROUBLESHOOTING.md` 파일을 참고하세요.

---

## 백엔드 팀에게 전달할 정보

배포가 완료되면 백엔드 팀에게 다음 정보를 전달하세요:

### 1. API URL

**Docker Compose 환경 (백엔드 컨테이너에서 접근)**:
```
http://risk-scoring:5001
```

**EC2 서버 외부 접근 (테스트용)**:
```
http://<EC2-PUBLIC-IP>:5001
```

### 2. Health Check

```bash
curl http://localhost:5001/health
# 또는 EC2 서버 IP로
curl http://<EC2-PUBLIC-IP>:5001/health
```

### 3. API 문서

```
http://<EC2-PUBLIC-IP>:5001/api-docs
```

### 4. 환경 변수 설정

백엔드 `.env` 파일에 추가:

```bash
RISK_SCORING_API_URL=http://risk-scoring:5001
```

---

## 문제 해결

배포 중 문제가 발생하면:

1. **로그 확인**: `docker-compose -f docker-compose.prod.yml logs risk-scoring`
2. **상태 확인**: `docker-compose -f docker-compose.prod.yml ps`
3. **문제 해결 가이드**: `TROUBLESHOOTING.md` 참고

---

## 요약

**백엔드 팀 요청**: EC2 서버에서 리스크 스코어링 API를 실행해야 함

**해야 할 일**:
1. EC2 서버에 SSH 접속
2. 프로젝트 클론/업데이트
3. 서브디렉토리 설정
4. 환경 변수 설정
5. Docker Compose로 배포
6. 배포 확인

**배포 완료 후**: 백엔드 팀에게 API URL (`http://risk-scoring:5001`) 전달

