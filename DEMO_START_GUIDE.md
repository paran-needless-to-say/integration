# 데모 화면 실행 가이드

프론트엔드와 백엔드를 연동하여 데모를 실행하는 방법입니다.

---

## 방법 1: 통합 스크립트 사용 (가장 쉬움)

### 1단계: 프로젝트 루트로 이동

```bash
cd /Users/yelim/Desktop/paran_final/trace-x
```

### 2단계: 환경 변수 설정

`.env` 파일이 있는지 확인하고, 없다면 생성:

```bash
# .env 파일 확인
cat .env

# 없다면 생성 (ETHERSCAN_API_KEY 필요)
cat > .env << EOF
ETHERSCAN_API_KEY=your_etherscan_api_key_here
EOF
```

### 3단계: 통합 스크립트 실행

```bash
# 실행 권한 부여 (최초 1회만)
chmod +x scripts/start-all.sh

# 모든 서비스 시작
./scripts/start-all.sh
```

### 4단계: 브라우저에서 접속

- **프론트엔드**: http://localhost:5173
- **백엔드 API**: http://localhost:8888
- **리스크 스코어링 API**: http://localhost:5001

### 서비스 중지

```bash
./scripts/stop-all.sh
```

---

## 방법 2: 개별 터미널에서 실행 (개발 모드)

### 준비 사항

1. **Etherscan API 키** 준비
2. **3개의 터미널 창** 열기

### Terminal 1: Risk Scoring API

```bash
cd /Users/yelim/Desktop/paran_final/trace-x/risk-scoring

# 가상환경 생성 (최초 1회만)
python3 -m venv venv

# 가상환경 활성화
source venv/bin/activate

# 의존성 설치 (최초 1회만)
pip install -r requirements.txt

# 서버 실행
python run_server.py
```

**확인**: http://localhost:5001/health 접속하여 JSON 응답 확인

### Terminal 2: Backend API

```bash
cd /Users/yelim/Desktop/paran_final/trace-x/backend

# 의존성 설치 (최초 1회만)
pip3 install -e .

# 환경 변수 설정
export ETHERSCAN_API_KEY=your_etherscan_api_key_here

# 서버 실행
python3 main.py
```

**확인**: 터미널에 "Running on http://0.0.0.0:8888" 메시지 확인

### Terminal 3: Frontend

```bash
cd /Users/yelim/Desktop/paran_final/trace-x/frontend

# 의존성 설치 (최초 1회만)
npm install

# 환경 변수 설정 (선택사항, 기본값: http://localhost:8888)
cat > .env << EOF
VITE_BACKEND_API_URL=http://localhost:8888
EOF

# 개발 서버 실행
npm run dev
```

**확인**: 터미널에 "Local: http://localhost:5173" 메시지 확인

### 브라우저에서 접속

http://localhost:5173 접속하여 데모 화면 확인

---

## 방법 3: Docker Compose 사용 (프로덕션 모드)

### 1단계: 환경 변수 설정

```bash
cd /Users/yelim/Desktop/paran_final/trace-x

# .env 파일 생성
cat > .env << EOF
ETHERSCAN_API_KEY=your_etherscan_api_key_here
FLASK_ENV=production
PYTHONUNBUFFERED=1
VITE_BACKEND_API_URL=http://localhost:8888
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF
```

### 2단계: Docker Compose 실행

```bash
# 전체 빌드 및 실행
docker-compose -f docker-compose.prod.yml up --build

# 또는 백그라운드 실행
docker-compose -f docker-compose.prod.yml up -d
```

### 3단계: 접속 확인

- **프론트엔드**: http://localhost:5173
- **백엔드 API**: http://localhost:8888
- **리스크 스코어링 API**: http://localhost:5001

### 서비스 중지

```bash
docker-compose -f docker-compose.prod.yml down
```

---

## 방법 4: EC2 서버에서 실행 (이미 배포된 경우)

### 1단계: EC2 서버 접속

```bash
ssh -i your-key.pem ubuntu@3.38.112.25
```

### 2단계: 서비스 상태 확인

```bash
cd ~/trace-x

# Docker 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 서비스가 실행 중이 아니면 시작
docker-compose -f docker-compose.prod.yml up -d
```

### 3단계: 브라우저에서 접속

- **프론트엔드**: http://3.38.112.25:5173
- **백엔드 API**: http://3.38.112.25:8888
- **리스크 스코어링 API**: http://3.38.112.25:5001

---

## 문제 해결

### 포트가 이미 사용 중

```bash
# 포트 사용 중인 프로세스 확인
lsof -ti:5001  # Risk Scoring API
lsof -ti:8888  # Backend
lsof -ti:5173  # Frontend

# 프로세스 종료
kill -9 <PID>
```

### 서비스가 시작되지 않음

```bash
# 로그 확인
tail -f logs/risk-scoring.log
tail -f logs/backend.log
tail -f logs/frontend.log

# 또는 Docker 로그
docker-compose -f docker-compose.prod.yml logs -f
```

### 프론트엔드에서 백엔드 연결 실패

1. 백엔드가 정상 실행 중인지 확인:
   ```bash
   curl http://localhost:8888/health
   ```

2. 프론트엔드 `.env` 파일 확인:
   ```bash
   cat frontend/.env
   # VITE_BACKEND_API_URL=http://localhost:8888 이어야 함
   ```

3. 브라우저 개발자 도구(F12)에서 Network 탭 확인하여 API 호출 실패 여부 확인

### Risk Scoring API 연결 실패

1. Risk Scoring API가 정상 실행 중인지 확인:
   ```bash
   curl http://localhost:5001/health
   ```

2. 백엔드 환경 변수 확인:
   ```bash
   echo $RISK_SCORING_API_URL
   # http://localhost:5001 또는 http://risk-scoring:5001 이어야 함
   ```

---

## 데모 사용 방법

### 1. Adhoc Analysis 페이지

1. http://localhost:5173 접속
2. "Adhoc Analysis" 메뉴 클릭
3. 테스트 주소 입력:
   - `0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be` (Binance Hot Wallet)
   - `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045` (Vitalik Buterin)
4. 체인 선택: Ethereum
5. "분석하기" 버튼 클릭
6. 결과 확인:
   - 리스크 점수 (0-100)
   - 리스크 레벨 (low/medium/high/critical)
   - 발동된 룰 목록
   - 거래 그래프 시각화

### 2. Dashboard 페이지

1. "Dashboard" 메뉴 클릭
2. 전체 거래 현황 확인
3. 실시간 모니터링 데이터 확인

### 3. Live Detection 페이지

1. "Live Detection" 메뉴 클릭
2. 실시간 거래 탐지 결과 확인

---

## 빠른 시작 요약

**가장 빠른 방법**:

```bash
# 1. 프로젝트 루트로 이동
cd /Users/yelim/Desktop/paran_final/trace-x

# 2. .env 파일 확인/생성
cat .env  # ETHERSCAN_API_KEY가 있는지 확인

# 3. 통합 스크립트 실행
chmod +x scripts/start-all.sh
./scripts/start-all.sh

# 4. 브라우저에서 접속
# http://localhost:5173
```

이제 데모를 사용할 수 있습니다!

