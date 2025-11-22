# 🎯 Trace-X: Blockchain Risk Analysis Platform

블록체인 주소의 위험도를 분석하는 통합 플랫폼

## 📋 목차

- [특징](#특징)
- [시스템 구조](#시스템-구조)
- [빠른 시작](#빠른-시작)
- [개발 환경 설정](#개발-환경-설정)
- [Docker로 실행](#docker로-실행)
- [프로젝트 구조](#프로젝트-구조)
- [API 문서](#api-문서)
- [문제 해결](#문제-해결)

---

## ✨ 특징

- 🔍 **Multi-hop 거래 분석**: 1-hop부터 3-hop까지 재귀적 거래 추적
- 🎯 **리스크 스코어링**: 50+ 룰 기반 위험도 평가
- 📊 **그래프 패턴 탐지**: Layering Chain, Cycle, Fan-in/out 등
- 🌐 **Multi-chain 지원**: Ethereum, BSC, Polygon
- 🚀 **실시간 분석**: 주소 입력 즉시 위험도 분석

---

## 🏗️ 시스템 구조

```
┌─────────────┐
│  Frontend   │  React + TypeScript
│ (Port 5173) │  사용자 인터페이스
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Backend   │  Flask + Etherscan API
│ (Port 8888) │  거래 데이터 수집
└──────┬──────┘
       │
       ↓
┌─────────────┐
│Risk Scoring │  Python + NetworkX
│ (Port 5001) │  위험도 분석
└─────────────┘
```

### 컴포넌트

1. **Frontend** (`frontend/`)

   - React + TypeScript + Vite
   - 주소 입력, 체인 선택, 결과 시각화

2. **Backend** (`backend/`)

   - Flask API
   - Etherscan API 연동
   - Multi-hop 거래 데이터 수집

3. **Risk Scoring** (`risk-scoring/`)
   - 거래 분석 엔진
   - 룰 기반 스코어링
   - 그래프 패턴 탐지

---

## 🚀 빠른 시작

### 필수 요구사항

- Python 3.9+
- Node.js 18+
- Etherscan API 키

### 1. 환경 변수 설정

`.env` 파일 생성:

```bash
cat > .env << EOF
ETHERSCAN_API_KEY=your_etherscan_api_key_here
EOF
```

> 💡 **API 키 발급**: [https://etherscan.io/apis](https://etherscan.io/apis)

### 2. 전체 실행 (권장)

```bash
# 한 번에 모든 서비스 시작
./scripts/start-all.sh
```

### 3. 접속

- 🌐 **Frontend**: [http://localhost:5173](http://localhost:5173)
- 🔧 **Backend**: [http://localhost:8888](http://localhost:8888)
- 📊 **Risk Scoring**: [http://localhost:5001](http://localhost:5001)

### 4. 중지

```bash
# 모든 서비스 중지
./scripts/stop-all.sh
```

---

## 🛠️ 개발 환경 설정

### Terminal 1: Risk Scoring API

```bash
cd risk-scoring

# 가상환경 생성 및 활성화
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
python run_server.py
```

✅ 확인: [http://localhost:5001/health](http://localhost:5001/health)

---

### Terminal 2: Backend

```bash
cd backend

# 의존성 설치
pip3 install -e .

# 환경 변수 설정
export ETHERSCAN_API_KEY=your_api_key_here

# 서버 실행
python3 main.py
```

✅ 확인: Backend가 8888 포트에서 실행 중

---

### Terminal 3: Frontend

```bash
cd frontend

# 의존성 설치
npm install

# 환경 변수 설정 (선택사항)
cat > .env << EOF
VITE_BACKEND_API_URL=http://localhost:8888
EOF

# 개발 서버 실행
npm run dev
```

✅ 확인: [http://localhost:5173](http://localhost:5173)

---

## 🐳 Docker로 실행

### 1. Docker Compose 사용 (권장)

```bash
# 환경 변수 설정
export ETHERSCAN_API_KEY=your_api_key_here

# 전체 빌드 및 실행
docker-compose up --build

# 백그라운드 실행
docker-compose up -d

# 중지
docker-compose down
```

### 2. 개별 서비스 빌드

```bash
# Risk Scoring
docker build -t trace-x-risk-scoring ./risk-scoring

# Backend
docker build -t trace-x-backend ./backend

# Frontend
docker build -t trace-x-frontend ./frontend
```

---

## 📁 프로젝트 구조

```
trace-x/
├── frontend/              # React 프론트엔드
│   ├── src/
│   │   ├── pages/         # 페이지 컴포넌트
│   │   ├── components/    # 재사용 컴포넌트
│   │   ├── services/      # API 서비스
│   │   └── types/         # TypeScript 타입
│   ├── package.json
│   └── Dockerfile
│
├── backend/               # Flask 백엔드
│   ├── src/
│   │   ├── api/           # API 라우트
│   │   │   ├── analysis.py      # 거래 분석
│   │   │   ├── risk_scoring.py  # 리스크 스코어링 연동
│   │   │   ├── dashboard.py     # 대시보드
│   │   │   └── live_detection.py
│   │   ├── types/         # 타입 정의
│   │   └── constants/     # 상수
│   ├── main.py
│   └── Dockerfile
│
├── risk-scoring/          # 리스크 스코어링 API
│   ├── api/
│   │   └── routes/        # API 엔드포인트
│   ├── core/
│   │   ├── aggregation/   # 그래프 패턴 탐지
│   │   ├── scoring/       # 스코어링 엔진
│   │   ├── rules/         # 룰 평가
│   │   └── data/          # 데이터 소스
│   ├── rules/             # YAML 룰 정의
│   ├── models/            # 학습된 모델
│   ├── run_server.py
│   └── Dockerfile
│
├── docs/                  # 통합 문서
│   ├── API.md
│   ├── SETUP.md
│   └── ARCHITECTURE.md
│
├── scripts/               # 유틸리티 스크립트
│   ├── start-all.sh       # 전체 시작
│   ├── stop-all.sh        # 전체 중지
│   └── test-integration.sh
│
├── .github/
│   └── workflows/         # CI/CD
│
├── docker-compose.yml     # Docker Compose 설정
├── .gitignore
├── .env.example           # 환경 변수 예시
└── README.md              # 이 파일
```

---

## 📚 API 문서

### Backend API

#### 1. Risk Scoring (리스크 스코어링)

```bash
POST /api/analysis/risk-scoring
```

**Request:**

```json
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "chain_id": 1,
  "max_hops": 3,
  "analysis_type": "basic"
}
```

**Response:**

```json
{
  "data": {
    "target_address": "0x...",
    "risk_score": 85,
    "risk_level": "high",
    "fired_rules": [...],
    "risk_tags": ["sanctioned", "mixer"],
    "explanation": "..."
  }
}
```

#### 2. Fund Flow Analysis

```bash
GET /api/analysis/fund-flow?address=0x...&chain_id=1
```

#### 3. Bridge Analysis

```bash
GET /api/analysis/bridge?tx_hash=0x...&chain_id=1
```

자세한 API 문서는 [docs/API.md](docs/API.md) 참조

---

## 🧪 테스트

### 1. 통합 테스트

```bash
# 전체 통합 테스트
./scripts/test-integration.sh
```

### 2. 개별 서비스 테스트

```bash
# Risk Scoring API
curl http://localhost:5001/health

# Backend API
curl http://localhost:8888/api/dashboard/summary

# Frontend
curl http://localhost:5173
```

### 3. 주소 분석 테스트

1. Frontend 접속: [http://localhost:5173](http://localhost:5173)
2. "Adhoc Analysis" 메뉴 클릭
3. 테스트 주소 입력: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`
4. 체인 선택: **Ethereum**
5. "분석하기" 클릭
6. 결과 확인
7. "심층 분석 (3-hop)" 클릭
8. 심층 분석 결과 확인

---

## 🐛 문제 해결

### 1. Etherscan API 에러

**증상**: `Scoring analysis failed: ...`

**해결**:

```bash
# API 키 확인
echo $ETHERSCAN_API_KEY

# 설정되지 않았다면
export ETHERSCAN_API_KEY=your_key_here
```

---

### 2. 포트 충돌

**증상**: `Address already in use`

**해결**:

```bash
# 포트 사용 확인
lsof -ti:5001  # Risk Scoring
lsof -ti:8888  # Backend
lsof -ti:5173  # Frontend

# 프로세스 종료
./scripts/stop-all.sh
```

---

### 3. Docker 이슈

**증상**: 컨테이너가 시작되지 않음

**해결**:

```bash
# 로그 확인
docker-compose logs risk-scoring
docker-compose logs backend
docker-compose logs frontend

# 재빌드
docker-compose down
docker-compose up --build
```

---

### 4. Risk Scoring API 연결 실패

**증상**: `Risk scoring API call failed`

**해결**:

```bash
# Risk Scoring API 상태 확인
curl http://localhost:5001/health

# 실행 중이 아니면
cd risk-scoring
source venv/bin/activate
python run_server.py
```

---

## 📊 성능 고려사항

| 분석 타입 | Hop 수 | 예상 시간 | API 호출 횟수 |
| --------- | ------ | --------- | ------------- |
| 기본 분석 | 1-hop  | ~5초      | 1-2회         |
| 심층 분석 | 3-hop  | ~15-30초  | 10-20회       |

**최적화 팁:**

- ✅ 무료 Etherscan API: 초당 5 요청 제한
- ✅ 유료 API 키 사용 권장 (Pro: 초당 50 요청)
- ✅ `max_hops`를 2 이하로 설정 (빠른 분석)
- ✅ 캐싱 활용 (동일 주소 재분석 시)

---

## 🔒 보안

- 🔑 API 키는 `.env` 파일에만 저장
- 🚫 `.env` 파일은 Git에 커밋하지 않음
- 🔐 프로덕션 환경에서는 HTTPS 사용 권장
- 📝 Rate limiting 설정 권장

---

## 🤝 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 라이선스

MIT License

---

## 👥 팀

- **Frontend**: React + TypeScript
- **Backend**: Flask + Etherscan
- **Risk Scoring**: Python + ML

---

## 📖 추가 문서

- [**핵심 로직 가이드**](docs/CORE_LOGIC.md) ⭐ - 프로젝트의 핵심 로직과 데이터 플로우 상세 설명
- [통합 가이드](docs/INTEGRATION_GUIDE.md)
- [통합 요약](docs/INTEGRATION_SUMMARY.md)
- [API 상세 문서](docs/API.md)
- [시스템 아키텍처](docs/ARCHITECTURE.md)
- [배포 가이드](docs/DEPLOYMENT.md)

---

## 🎉 Quick Links

- 🌐 Frontend: [http://localhost:5173](http://localhost:5173)
- 🔧 Backend: [http://localhost:8888](http://localhost:8888)
- 📊 Risk Scoring: [http://localhost:5001](http://localhost:5001)
- 📚 API Docs: [docs/API.md](docs/API.md)
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/trace-x/issues)

---

**Made with ❤️ by the Trace-X Team**
