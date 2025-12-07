# Trace-X: Blockchain Risk Analysis Platform

블록체인 주소의 위험도를 분석하는 통합 플랫폼입니다.

https://youtu.be/dbo9gwlLPCw?si=TTSQCYIgirdBvLe7

## 목차

- [프로젝트 소개](#프로젝트-소개)
- [주요 기능](#주요-기능)
- [시스템 구조](#시스템-구조)
- [빠른 시작](#빠른-시작)
- [설치 및 설정](#설치-및-설정)
- [Docker로 실행](#docker로-실행)
- [프로젝트 구조](#프로젝트-구조)
- [API 사용](#api-사용)
- [테스트](#테스트)
- [문제 해결](#문제-해결)
- [문서](#문서)

---

## 프로젝트 소개

Trace-X는 블록체인 주소의 거래 히스토리를 분석하여 위험도를 평가하는 플랫폼입니다.
사용자가 주소를 입력하면, 해당 주소와 연결된 모든 거래를 추적하여
AML(반세탁) 규칙 기반으로 위험도를 점수화합니다.

### 핵심 가치

- **정확성**: 50개 이상의 룰 기반 위험도 평가
- **신속성**: 1-hop 기본 분석은 약 5초 내 결과 제공
- **심층 분석**: 3-hop 심층 분석으로 복잡한 세탁 패턴 탐지
- **다중 체인 지원**: Ethereum, BSC, Polygon 등 여러 체인 지원

---

## 주요 기능

### 1. Multi-hop 거래 분석

주소의 거래 관계를 재귀적으로 추적합니다.
1-hop은 직접 거래, 2-hop은 1단계 상대방과의 거래, 3-hop은 2단계 상대방과의 거래를 분석합니다.

### 2. 리스크 스코어링

TRACE-X 룰북 기반으로 위험도를 0-100점 사이의 점수로 평가합니다.
점수는 Compliance(규정 준수), Exposure(노출), Behavior(행동 패턴) 3가지 카테고리로 분류됩니다.

### 3. 그래프 패턴 탐지

세탁에 자주 사용되는 패턴을 탐지합니다:

- Layering Chain: 다층 구조의 자금 이동
- Cycle: 순환 구조의 거래
- Fan-in/Fan-out: 다수의 주소로부터 집중되거나 분산되는 패턴

### 4. Multi-chain 지원

현재 Ethereum, BSC, Polygon을 지원하며, 추가 체인 지원이 가능한 구조로 설계되었습니다.

### 5. 실시간 분석

주소 입력 즉시 위험도 분석 결과를 제공합니다.

---

## 시스템 구조

Trace-X는 3-tier 아키텍처로 구성되어 있습니다:

```
Frontend (React + TypeScript)
    ↓ HTTP API 호출
Backend (Flask API)
    ↓ Etherscan API로 거래 데이터 수집
    ↓ 그래프 데이터 생성 및 변환
    ↓ HTTP API 호출
Risk Scoring API (Python + NetworkX)
    ↓ 룰 평가 및 점수 계산
    ↓ 결과 반환
Backend → Frontend (결과 표시)
```

### 컴포넌트 상세

#### Frontend (포트 5173)

- **역할**: 사용자 인터페이스 제공
- **기술**: React 19, TypeScript, Vite
- **주요 기능**:
  - 주소 입력 및 체인 선택
  - 분석 결과 시각화 (그래프, 점수, 룰 목록)
  - Dashboard, Live Detection, Adhoc Analysis 페이지

#### Backend (포트 8888)

- **역할**: 데이터 수집, 그래프 생성, API 게이트웨이
- **기술**: Flask, Python 3.10+
- **주요 기능**:
  - Etherscan API를 통한 거래 데이터 수집
  - Multi-hop 그래프 데이터 생성
  - 리스크 스코어링 API 호출 및 결과 전달

#### Risk Scoring API (포트 5001)

- **역할**: 거래 분석 및 위험도 평가
- **기술**: Flask, Python 3.10+, NetworkX
- **주요 기능**:
  - TRACE-X 룰북 기반 룰 평가
  - 그래프 패턴 탐지 (advanced 모드)
  - 리스크 점수 계산 및 집계

---

## 빠른 시작

### 필수 요구사항

- **Python**: 3.9 이상 (백엔드 및 리스크 스코어링 API용)
- **Node.js**: 18 이상 (프론트엔드용)
- **Etherscan API 키**: [https://etherscan.io/apis](https://etherscan.io/apis)에서 발급

### 1단계: 저장소 클론

통합 레포에서 클론하거나, 각 컴포넌트를 개별 레포에서 클론할 수 있습니다.

#### 통합 레포 클론 (권장)

```bash
git clone https://github.com/paran-needless-to-say/integration.git
cd integration

# 서브모듈 초기화 (각 컴포넌트 자동 클론)
git submodule update --init --recursive
```

#### 개별 레포 클론

```bash
# 백엔드
git clone https://github.com/paran-needless-to-say/100end.git

# 프론트엔드
git clone https://github.com/paran-needless-to-say/frontend.git

# 리스크 스코어링 API
git clone https://github.com/paran-needless-to-say/aml-risk-engine2.git
```

### 2단계: 환경 변수 설정

`.env` 파일을 생성하여 Etherscan API 키를 설정합니다:

```bash
cat > .env << EOF
ETHERSCAN_API_KEY=your_etherscan_api_key_here
EOF
```

**API 키 발급 방법**:

1. [Etherscan.io](https://etherscan.io)에 가입
2. [API Keys 페이지](https://etherscan.io/apis)에서 API 키 발급
3. `.env` 파일에 입력

### 3단계: 전체 실행 (권장)

통합 스크립트를 사용하여 모든 서비스를 한 번에 시작할 수 있습니다:

```bash
# 실행 권한 부여 (최초 1회)
chmod +x scripts/start-all.sh

# 모든 서비스 시작
./scripts/start-all.sh
```

이 스크립트는 다음 순서로 서비스를 시작합니다:

1. Risk Scoring API (포트 5001)
2. Backend API (포트 8888)
3. Frontend (포트 5173)

### 4단계: 접속 확인

브라우저에서 다음 주소로 접속하여 각 서비스가 정상 작동하는지 확인합니다:

- **Frontend**: [http://localhost:5173](http://localhost:5173)
- **Backend API**: [http://localhost:8888/api/dashboard/summary](http://localhost:8888/api/dashboard/summary)
- **Risk Scoring API**: [http://localhost:5001/health](http://localhost:5001/health)

### 5단계: 서비스 중지

모든 서비스를 중지하려면:

```bash
./scripts/stop-all.sh
```

---

## 설치 및 설정

### 개별 서비스 실행 (개발 모드)

각 서비스를 개별 터미널에서 실행하여 개발할 수 있습니다.

#### Terminal 1: Risk Scoring API

```bash
cd risk-scoring

# 가상환경 생성 (최초 1회)
python3 -m venv venv

# 가상환경 활성화
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
python run_server.py
```

정상 작동 확인: [http://localhost:5001/health](http://localhost:5001/health)

#### Terminal 2: Backend

```bash
cd backend

# 의존성 설치
pip3 install -e .

# 환경 변수 설정
export ETHERSCAN_API_KEY=your_api_key_here

# 서버 실행
python3 main.py
```

정상 작동 확인: Backend가 8888 포트에서 실행 중인지 확인

#### Terminal 3: Frontend

```bash
cd frontend

# 의존성 설치 (최초 1회)
npm install

# 환경 변수 설정 (선택사항)
cat > .env << EOF
VITE_BACKEND_API_URL=http://localhost:8888
EOF

# 개발 서버 실행
npm run dev
```

정상 작동 확인: [http://localhost:5173](http://localhost:5173)

---

## Docker로 실행

Docker Compose를 사용하여 모든 서비스를 컨테이너로 실행할 수 있습니다.

### Docker Compose 사용

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

### 개별 서비스 빌드

```bash
# Risk Scoring API
docker build -t trace-x-risk-scoring ./risk-scoring

# Backend
docker build -t trace-x-backend ./backend

# Frontend
docker build -t trace-x-frontend ./frontend
```

---

## 프로젝트 구조

```
trace-x/
├── frontend/              # React 프론트엔드
│   ├── src/
│   │   ├── pages/         # 페이지 컴포넌트
│   │   ├── components/    # 재사용 컴포넌트
│   │   ├── api/           # API 호출 함수
│   │   ├── services/      # 비즈니스 로직
│   │   └── types/         # TypeScript 타입 정의
│   ├── package.json
│   └── Dockerfile
│
├── backend/               # Flask 백엔드
│   ├── src/
│   │   ├── api/           # API 라우트
│   │   │   ├── analysis.py      # 거래 분석 엔드포인트
│   │   │   ├── risk_scoring.py  # 리스크 스코어링 연동
│   │   │   ├── dashboard.py     # 대시보드 API
│   │   │   └── live_detection.py
│   │   ├── types/         # 타입 정의
│   │   ├── constants/     # 상수 (체인 ID, RPC URL 등)
│   │   └── utils/         # 유틸리티 함수
│   ├── main.py
│   ├── pyproject.toml
│   └── Dockerfile
│
├── risk-scoring/          # 리스크 스코어링 API
│   ├── api/
│   │   └── routes/        # API 엔드포인트
│   ├── core/
│   │   ├── aggregation/   # 그래프 패턴 탐지
│   │   ├── scoring/       # 스코어링 엔진
│   │   ├── rules/         # 룰 평가
│   │   └── data/          # 데이터 소스 (SDN 리스트 등)
│   ├── rules/             # YAML 룰 정의 파일
│   ├── models/            # 학습된 ML 모델 (선택사항)
│   ├── run_server.py
│   └── Dockerfile
│
├── docs/                  # 통합 문서
│   ├── ARCHITECTURE.md    # 시스템 아키텍처 상세 설명
│   ├── API.md             # API 사용 가이드
│   ├── CORE_LOGIC.md      # 핵심 로직 및 데이터 플로우
│   ├── INTEGRATION_GUIDE.md  # 통합 가이드
│   └── ...                # 기타 문서
│
├── scripts/               # 유틸리티 스크립트
│   ├── start-all.sh       # 전체 서비스 시작
│   ├── stop-all.sh        # 전체 서비스 중지
│   ├── health-check.sh    # 서비스 상태 확인
│   └── test-integration.sh  # 통합 테스트
│
├── docker-compose.yml     # Docker Compose 설정
├── .gitignore
├── .env.example           # 환경 변수 예시
└── README.md              # 이 파일
```

---

## API 사용

### 주요 엔드포인트

#### 1. 리스크 스코어링 분석 (메인 엔드포인트)

**엔드포인트**: `POST /api/analysis/risk-scoring`

**설명**: 주소를 입력받아 Multi-hop 거래 데이터를 수집하고 리스크 스코어링을 수행합니다.

**요청 예시**:

```bash
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "chain_id": 1,
    "max_hops": 3,
    "analysis_type": "basic"
  }'
```

**응답 예시**:

```json
{
  "data": {
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "chain": "ethereum",
    "final_score": 85,
    "risk_level": "high",
    "risk_tags": ["sanction_exposure", "large_amount"],
    "fired_rules": [
      {
        "rule_id": "C-001",
        "score": 30,
        "description": "Sanctioned address exposure"
      }
    ],
    "explanation": "High risk due to sanctioned address exposure...",
    "completed_at": "2025-01-15T10:30:00Z"
  }
}
```

**파라미터 설명**:

- `address` (필수): 분석할 주소 (0x로 시작하는 16진수 문자열)
- `chain_id` (필수): 체인 ID (1=Ethereum, 56=BSC, 137=Polygon)
- `max_hops` (선택): 최대 홉 수 (기본값: 3, 권장: 1-5)
- `max_addresses_per_direction` (선택): 방향당 최대 주소 수 (기본값: 10)
- `analysis_type` (선택): "basic" 또는 "advanced" (기본값: "basic")

#### 2. Fund Flow 분석

**엔드포인트**: `GET /api/analysis/fund-flow`

**설명**: 거래 그래프 데이터를 조회합니다 (리스크 스코어링 제외).

**요청 예시**:

```bash
curl "http://localhost:8888/api/analysis/fund-flow?chain_id=1&address=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb&max_hops=2"
```

#### 3. Transaction Flow 분석

**엔드포인트**: `GET /api/analysis/transaction-flow`

**설명**: 특정 트랜잭션 해시를 기반으로 자금 흐름을 분석합니다.

#### 4. Bridge 분석

**엔드포인트**: `GET /api/analysis/bridge`

**설명**: 브리지 트랜잭션을 분석합니다.

### API 문서

더 자세한 API 문서는 [docs/API.md](docs/API.md)를 참조하세요.

---

## 테스트

### 통합 테스트

모든 서비스가 정상 작동하는지 확인합니다:

```bash
./scripts/test-integration.sh
```

### 개별 서비스 테스트

```bash
# Risk Scoring API
curl http://localhost:5001/health

# Backend API
curl http://localhost:8888/api/dashboard/summary

# Frontend
curl http://localhost:5173
```

### 주소 분석 테스트

1. 브라우저에서 [http://localhost:5173](http://localhost:5173) 접속
2. "Adhoc Analysis" 메뉴 클릭
3. 테스트 주소 입력: `0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be` (Binance Hot Wallet)
4. 체인 선택: Ethereum
5. "분석하기" 버튼 클릭
6. 결과 확인:
   - 리스크 점수 (0-100)
   - 리스크 레벨 (low/medium/high/critical)
   - 발동된 룰 목록
   - 거래 그래프 시각화
7. "심층 분석 (3-hop)" 버튼 클릭 (선택사항)
8. 심층 분석 결과 확인

---

## 문제 해결

### 1. Etherscan API 에러

**증상**: `Scoring analysis failed: Etherscan API error...`

**원인**:

- Etherscan API 키가 설정되지 않음
- API 레이트 리밋 초과
- 잘못된 API 키

**해결**:

```bash
# API 키 확인
echo $ETHERSCAN_API_KEY

# 설정되지 않았다면
export ETHERSCAN_API_KEY=your_api_key_here

# 백엔드 재시작
cd backend
python3 main.py
```

**추가 참고**:

- 무료 Etherscan API는 초당 5 요청으로 제한됩니다
- 더 많은 요청이 필요하면 Pro 플랜 사용을 고려하세요

### 2. 포트 충돌

**증상**: `Address already in use` 또는 포트가 이미 사용 중임

**원인**: 해당 포트에서 이미 다른 프로세스가 실행 중

**해결**:

```bash
# 포트 사용 확인
lsof -ti:5001  # Risk Scoring API
lsof -ti:8888  # Backend
lsof -ti:5173  # Frontend

# 프로세스 종료 (PID는 위 명령어 결과에서 확인)
kill -9 <PID>

# 또는 통합 스크립트 사용
./scripts/stop-all.sh
```

### 3. Docker 이슈

**증상**: 컨테이너가 시작되지 않거나 오류 발생

**해결**:

```bash
# 로그 확인
docker-compose logs risk-scoring
docker-compose logs backend
docker-compose logs frontend

# 재빌드
docker-compose down
docker-compose up --build

# 컨테이너 상태 확인
docker-compose ps
```

### 4. Risk Scoring API 연결 실패

**증상**: `Risk scoring API call failed: Connection refused`

**원인**: Risk Scoring API가 실행되지 않음

**해결**:

```bash
# Risk Scoring API 상태 확인
curl http://localhost:5001/health

# 실행 중이 아니면 시작
cd risk-scoring
source venv/bin/activate
python run_server.py
```

**참고**: Backend가 Risk Scoring API를 호출하므로, Risk Scoring API가 먼저 실행되어야 합니다.

### 5. 거래 데이터가 없음

**증상**: 분석 결과가 비어있거나 스코어가 0

**원인**:

- 주소에 거래 내역이 없음
- Etherscan API 호출 실패

**해결**:

- 거래 내역이 있는 주소 사용 (예: 유명 CEX 주소)
- 백엔드 로그 확인하여 API 호출 성공 여부 확인
- 테스트 주소: `0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be` (Binance Hot Wallet)

### 6. Python 버전 충돌

**증상**: `ImportError` 또는 버전 호환성 오류

**원인**: 시스템 Python과 가상환경 Python 버전 불일치

**해결**:

```bash
# 가상환경 Python 버전 확인
cd backend  # 또는 risk-scoring
source venv/bin/activate
python --version

# Python 3.10 이상인지 확인
# 버전이 다르면 가상환경 재생성
rm -rf venv
python3.10 -m venv venv  # 또는 python3.11, python3.12
source venv/bin/activate
pip install -r requirements.txt  # 또는 pip install -e .
```

---

## 성능 고려사항

### 응답 시간

| 분석 타입 | Hop 수 | 예상 시간  | 사용 시나리오              |
| --------- | ------ | ---------- | -------------------------- |
| 기본 분석 | 1-hop  | 약 5초     | 실시간 대시보드, 빠른 확인 |
| 심층 분석 | 3-hop  | 약 15-30초 | 상세 분석, 세탁 패턴 탐지  |

**참고**:

- Hop 수가 많을수록 분석 시간이 길어집니다
- `max_addresses_per_direction`을 줄이면 응답 시간이 단축됩니다

### Rate Limit

| API       | 무료 플랜 | Pro 플랜   | 권장                    |
| --------- | --------- | ---------- | ----------------------- |
| Etherscan | 5 req/sec | 50 req/sec | 프로덕션: Pro 플랜 권장 |

### 최적화 팁

1. **1-hop 기본 분석 사용**: 빠른 응답이 필요한 경우
2. **Hop 수 조절**: 필요에 따라 `max_hops`를 1-3 사이로 조절
3. **주소 수 제한**: `max_addresses_per_direction`을 10 이하로 설정
4. **캐싱 활용**: 동일 주소 재분석 시 캐싱 사용 (향후 구현 예정)

---

## 보안

### API 키 관리

- API 키는 `.env` 파일에만 저장합니다
- `.env` 파일은 절대 Git에 커밋하지 않습니다 (이미 `.gitignore`에 포함됨)
- 프로덕션 환경에서는 환경 변수나 시크릿 관리 서비스 사용을 권장합니다

### 프로덕션 배포

자세한 배포 가이드는 [프로덕션 배포 가이드](docs/DEPLOYMENT.md)를 참조하세요.

주요 권장사항:

- HTTPS 사용을 권장합니다
- Rate limiting 설정을 권장합니다
- CORS 설정을 프로덕션 도메인으로 제한합니다
- Docker Compose를 사용한 컨테이너 배포 권장
- 환경 변수는 `.env` 파일 또는 시크릿 관리 서비스 사용

---

## 문서

### 핵심 문서

1. **[시스템 아키텍처](docs/ARCHITECTURE.md)**: 전체 시스템 구조, 컴포넌트 상세, 데이터 플로우
2. **[API 사용 가이드](docs/API.md)**: 모든 API 엔드포인트 및 사용 방법
3. **[핵심 로직 가이드](docs/CORE_LOGIC.md)**: 프로젝트의 핵심 로직과 데이터 플로우 상세 설명

### 통합 가이드

- [통합 가이드](docs/INTEGRATION_GUIDE.md): 시스템 통합 및 실행 방법

### 필수 문서

- **[빠른 배포 가이드](QUICK_DEPLOY.md)**: EC2 서버 접속 후 빠르게 배포하기 (5단계)
- **[백엔드 팀 전달 문서](BACKEND_TEAM_HANDOFF.md)**: 리스크 스코어링 API 사용 가이드 및 배포 현황
- **[문제 해결 가이드](TROUBLESHOOTING.md)**: 배포 중 발생하는 문제 해결 방법

### 추가 문서

- [프로덕션 배포 가이드](docs/DEPLOYMENT.md): EC2, Docker를 사용한 프로덕션 환경 배포 방법 (상세)
- [API 문서](docs/API.md): API 사용 가이드
- [통합 가이드](docs/INTEGRATION_GUIDE.md): 시스템 통합 및 실행 방법
- [아키텍처 문서](docs/ARCHITECTURE.md): 시스템 구조 설명

---

## 원격 레포

Trace-X는 통합 레포와 개별 컴포넌트 레포로 구성되어 있습니다.

### 통합 레포 (모노레포)

- **GitHub**: [https://github.com/paran-needless-to-say/integration](https://github.com/paran-needless-to-say/integration)
- **설명**: 모든 컴포넌트, 통합 스크립트, 문서를 포함한 통합 레포
- **사용 시나리오**: 로컬 개발, 통합 테스트, 전체 시스템 실행

### 개별 레포

- **Backend**: [https://github.com/paran-needless-to-say/100end](https://github.com/paran-needless-to-say/100end)
- **Frontend**: [https://github.com/paran-needless-to-say/frontend](https://github.com/paran-needless-to-say/frontend)
- **Risk Scoring API**: [https://github.com/paran-needless-to-say/aml-risk-engine2](https://github.com/paran-needless-to-say/aml-risk-engine2)
- **사용 시나리오**: 각 컴포넌트별 배포, 팀별 독립 개발

---

## 라이선스

MIT License

---

## 문의 및 지원

- **통합 레포 이슈**: [integration 레포지토리](https://github.com/paran-needless-to-say/integration)
- **백엔드 이슈**: [100end 레포지토리](https://github.com/paran-needless-to-say/100end)
- **프론트엔드 이슈**: [frontend 레포지토리](https://github.com/paran-needless-to-say/frontend)
- **리스크 스코어링 이슈**: [aml-risk-engine2 레포지토리](https://github.com/paran-needless-to-say/aml-risk-engine2)

---

Made with ❤️ by the Trace-X Team
