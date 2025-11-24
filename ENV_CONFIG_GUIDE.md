# 환경 변수 설정 가이드

로컬 개발과 EC2 배포 시 환경 변수 설정이 다릅니다.

---

## 환경 변수 요약

| 변수명                 | 로컬 개발               | EC2 배포                                                  | 설명                                    |
| ---------------------- | ----------------------- | --------------------------------------------------------- | --------------------------------------- |
| `ETHERSCAN_API_KEY`    | ✅ 필수                 | ✅ 필수                                                   | Etherscan API 키 (동일)                 |
| `VITE_BACKEND_API_URL` | `http://localhost:8888` | `http://3.38.112.25:8888`                                 | 프론트엔드 빌드 시 백엔드 URL           |
| `RISK_SCORING_API_URL` | `http://localhost:5001` | `http://risk-scoring:5001` 또는 `http://3.38.112.25:5001` | 백엔드에서 리스크 스코어링 API 호출 URL |
| `BACKEND_API_URL`      | 사용 안 함              | 사용 안 함                                                | 실제로는 `VITE_BACKEND_API_URL` 사용    |

---

## 로컬 개발 환경 (.env)

```bash
# Etherscan API 키 (필수)
ETHERSCAN_API_KEY=CUBGE5DQECFRP4K9273MH2WEXU8STMB68Y

# 프론트엔드 빌드 시 사용
VITE_BACKEND_API_URL=http://localhost:8888

# 백엔드 런타임 시 사용 (로컬에서는 localhost)
RISK_SCORING_API_URL=http://localhost:5001

# Flask 환경
FLASK_ENV=development
PYTHONUNBUFFERED=1
```

**사용 시나리오**: 로컬에서 `./scripts/start-all.sh` 또는 개별 터미널로 실행

---

## EC2 배포 환경 (.env)

### 옵션 1: Docker Compose 내부 네트워크 사용 (권장)

```bash
# Etherscan API 키 (필수)
ETHERSCAN_API_KEY=CUBGE5DQECFRP4K9273MH2WEXU8STMB68Y

# 프론트엔드 빌드 시 사용 (EC2 Public IP 필수!)
VITE_BACKEND_API_URL=http://3.38.112.25:8888

# 백엔드 런타임 시 사용 (Docker 내부 네트워크)
RISK_SCORING_API_URL=http://risk-scoring:5001

# Flask 환경
FLASK_ENV=production
PYTHONUNBUFFERED=1
```

**설명**:

- `VITE_BACKEND_API_URL`: 프론트엔드가 **브라우저에서** 백엔드를 호출하므로 EC2 Public IP 필요
- `RISK_SCORING_API_URL`: 백엔드가 **Docker 컨테이너 내부에서** 리스크 스코어링 API를 호출하므로 서비스 이름(`risk-scoring`) 사용 가능

### 옵션 2: 외부 접근 모두 EC2 Public IP 사용

```bash
# Etherscan API 키 (필수)
ETHERSCAN_API_KEY=CUBGE5DQECFRP4K9273MH2WEXU8STMB68Y

# 프론트엔드 빌드 시 사용
VITE_BACKEND_API_URL=http://3.38.112.25:8888

# 백엔드 런타임 시 사용 (외부 접근)
RISK_SCORING_API_URL=http://3.38.112.25:5001

# Flask 환경
FLASK_ENV=production
PYTHONUNBUFFERED=1
```

**설명**:

- `RISK_SCORING_API_URL`을 EC2 Public IP로 설정하면, 백엔드가 외부 네트워크를 통해 리스크 스코어링 API를 호출합니다.
- 이 방식은 네트워크 오버헤드가 있지만, 컨테이너 간 네트워크 문제가 있을 때 유용합니다.

**참고**: `docker-compose.prod.yml`에서는 기본값으로 `http://3.38.112.25:5001`이 설정되어 있습니다:

```yaml
environment:
  - RISK_SCORING_API_URL=${RISK_SCORING_API_URL:-http://3.38.112.25:5001}
```

---

## 환경 변수별 용도 설명

### 1. `ETHERSCAN_API_KEY`

- **용도**: 백엔드에서 Etherscan API 호출 시 인증
- **사용 위치**: Backend (Etherscan API 클라이언트)
- **로컬/EC2 동일**: `CUBGE5DQECFRP4K9273MH2WEXU8STMB68Y`

### 2. `VITE_BACKEND_API_URL`

- **용도**: 프론트엔드 빌드 시 백엔드 API URL 하드코딩
- **사용 위치**: Frontend 빌드 시점 (환경 변수로 주입되어 JavaScript 코드에 포함됨)
- **특징**: `VITE_` 접두사가 있으면 빌드 시점에 주입됨
- **로컬**: `http://localhost:8888`
- **EC2**: `http://3.38.112.25:8888` (EC2 Public IP 필수!)

**왜 EC2 Public IP가 필요한가?**

- 프론트엔드는 **브라우저에서 실행**됩니다.
- 브라우저는 사용자의 컴퓨터에서 실행되므로, EC2 서버 내부 네트워크(`localhost`, `risk-scoring`)에 접근할 수 없습니다.
- 따라서 외부에서 접근 가능한 EC2 Public IP가 필요합니다.

### 3. `RISK_SCORING_API_URL`

- **용도**: 백엔드에서 리스크 스코어링 API 호출 시 사용
- **사용 위치**: Backend 런타임 (Python 코드)
- **로컬**: `http://localhost:5001`
- **EC2 옵션 1**: `http://risk-scoring:5001` (Docker 내부 네트워크, 빠름)
- **EC2 옵션 2**: `http://3.38.112.25:5001` (외부 접근, docker-compose.prod.yml 기본값)

**어떤 것을 사용해야 하나?**

- Docker Compose로 실행 시: `http://risk-scoring:5001` 권장 (빠르고 안정적)
- 컨테이너 간 네트워크 문제가 있을 때: `http://3.38.112.25:5001` 사용

---

## EC2 서버에서 환경 변수 설정 방법

### 1단계: EC2 서버 접속

```bash
ssh -i your-key.pem ubuntu@3.38.112.25
```

### 2단계: 프로젝트 디렉토리로 이동

```bash
cd ~/trace-x
```

### 3단계: .env 파일 생성/수정

```bash
# .env 파일 편집
nano .env
```

다음 내용 입력:

```bash
# Etherscan API 키
ETHERSCAN_API_KEY=CUBGE5DQECFRP4K9273MH2WEXU8STMB68Y

# 프론트엔드 빌드 시 사용 (EC2 Public IP 필수!)
VITE_BACKEND_API_URL=http://3.38.112.25:8888

# 백엔드 런타임 시 사용 (Docker 내부 네트워크 권장)
RISK_SCORING_API_URL=http://risk-scoring:5001

# Flask 환경
FLASK_ENV=production
PYTHONUNBUFFERED=1
```

### 4단계: 저장 및 확인

```bash
# 파일 저장 (nano: Ctrl+O, Enter, Ctrl+X)

# 내용 확인
cat .env
```

### 5단계: Docker Compose 재빌드 및 재시작

```bash
# 서비스 중지
docker-compose -f docker-compose.prod.yml down

# 프론트엔드 재빌드 (VITE_BACKEND_API_URL 변경 시 필수!)
docker-compose -f docker-compose.prod.yml up -d --build

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f
```

**중요**: `VITE_BACKEND_API_URL`을 변경했다면 반드시 프론트엔드를 **재빌드**해야 합니다!

---

## 체크리스트

### 로컬 개발

- [ ] `ETHERSCAN_API_KEY` 설정
- [ ] `VITE_BACKEND_API_URL=http://localhost:8888`
- [ ] `RISK_SCORING_API_URL=http://localhost:5001`

### EC2 배포

- [ ] `ETHERSCAN_API_KEY` 설정
- [ ] `VITE_BACKEND_API_URL=http://3.38.112.25:8888` (EC2 Public IP로 변경!)
- [ ] `RISK_SCORING_API_URL=http://risk-scoring:5001` 또는 `http://3.38.112.25:5001`
- [ ] 프론트엔드 재빌드 (환경 변수 변경 시)

---

## 문제 해결

### 프론트엔드에서 백엔드 연결 실패

**증상**: 브라우저 콘솔에서 `Failed to fetch` 또는 `Network Error`

**원인**: `VITE_BACKEND_API_URL`이 잘못 설정됨

**해결**:

1. EC2에서 `.env` 파일 확인:

   ```bash
   cat .env | grep VITE_BACKEND_API_URL
   ```

   - `http://localhost:8888` → `http://3.38.112.25:8888`로 변경 필요

2. 프론트엔드 재빌드:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build frontend
   ```

### 백엔드에서 리스크 스코어링 API 연결 실패

**증상**: 백엔드 로그에서 `Connection refused` 또는 `Name resolution failed`

**원인**: `RISK_SCORING_API_URL`이 잘못 설정됨

**해결**:

1. Docker Compose로 실행 중이라면:

   ```bash
   # .env 파일에 설정
   RISK_SCORING_API_URL=http://risk-scoring:5001
   ```

2. 외부 접근이 필요하다면:

   ```bash
   # .env 파일에 설정
   RISK_SCORING_API_URL=http://3.38.112.25:5001
   ```

3. 백엔드 재시작:
   ```bash
   docker-compose -f docker-compose.prod.yml restart backend
   ```

---

## 요약

**로컬 개발**:

- 모든 URL은 `localhost` 사용

**EC2 배포**:

- `VITE_BACKEND_API_URL`: **반드시 EC2 Public IP** (`http://3.38.112.25:8888`)
- `RISK_SCORING_API_URL`: Docker 내부 네트워크 (`http://risk-scoring:5001`) 또는 EC2 Public IP (`http://3.38.112.25:5001`)

**가장 중요한 점**: `VITE_BACKEND_API_URL`은 프론트엔드 빌드 시점에 주입되므로, 변경 시 **반드시 재빌드**가 필요합니다!
