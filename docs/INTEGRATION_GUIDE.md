# 🔗 프론트엔드-백엔드-리스크 스코어링 통합 가이드

## 📋 목차

1. [시스템 구조](#시스템-구조)
2. [환경 설정](#환경-설정)
3. [실행 방법](#실행-방법)
4. [API 플로우](#api-플로우)
5. [테스트](#테스트)
6. [트러블슈팅](#트러블슈팅)

---

## 시스템 구조

```
프론트엔드 (localhost:5173)
    ↓
백엔드 (localhost:8888)
    ↓ Etherscan API로 거래 데이터 수집
    ↓ 리스크 스코어링 API 호출
    ↓
리스크 스코어링 API (localhost:5001)
    ↓ 거래 분석 + 룰 평가
    ↓
결과 반환 → 백엔드 → 프론트엔드
```

### 역할 분담

1. **프론트엔드** (`frontend/`)

   - 사용자 인터페이스
   - 주소 입력 + 체인 선택
   - 분석 결과 시각화

2. **백엔드** (`100end/`)

   - Etherscan API로 거래 데이터 수집
   - Multi-hop 그래프 생성
   - 리스크 스코어링 API 호출
   - 결과를 프론트로 전달

3. **리스크 스코어링 API** (`Cryptocurrency-Graphs-of-graphs/`)
   - 거래 데이터 분석
   - 룰 기반 스코어링
   - 그래프 패턴 탐지

---

## 환경 설정

### 1. 리스크 스코어링 API

```bash
cd Cryptocurrency-Graphs-of-graphs

# 가상환경 활성화
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치 (이미 설치되었다면 생략)
pip install -r requirements.txt

# 서버 실행
python run_server.py
```

**포트**: 5001
**URL**: `http://localhost:5001`

---

### 2. 백엔드 설정

```bash
cd 100end

# 의존성 설치
pip3 install -e .

# 환경 변수 설정
export ETHERSCAN_API_KEY=your_etherscan_api_key_here

# 서버 실행
python3 main.py
```

**포트**: 8888
**URL**: `http://localhost:8888`

#### 환경 변수

| 변수명              | 필수 | 기본값 | 설명                                         |
| ------------------- | ---- | ------ | -------------------------------------------- |
| `ETHERSCAN_API_KEY` | ✅   | -      | Etherscan API 키 (https://etherscan.io/apis) |

---

### 3. 프론트엔드 설정

```bash
cd frontend

# 의존성 설치
npm install

# 환경 변수 설정
# .env 파일 생성
cat > .env << EOF
VITE_BACKEND_API_URL=http://localhost:8888
EOF

# 개발 서버 실행
npm run dev
```

**포트**: 5173
**URL**: `http://localhost:5173`

#### 환경 변수

| 변수명                 | 필수 | 기본값                  | 설명           |
| ---------------------- | ---- | ----------------------- | -------------- |
| `VITE_BACKEND_API_URL` | ❌   | `http://localhost:8888` | 백엔드 API URL |

---

## 실행 방법

### 전체 시스템 시작 (터미널 3개)

#### Terminal 1: 리스크 스코어링 API

```bash
cd /Users/yelim/Desktop/파란학기/Cryptocurrency-Graphs-of-graphs
source venv/bin/activate
python run_server.py
```

✅ 확인: `http://localhost:5001/health`

#### Terminal 2: 백엔드

```bash
cd /Users/yelim/Desktop/파란학기/100end
export ETHERSCAN_API_KEY=your_api_key
python3 main.py
```

✅ 확인: 백엔드가 8888 포트에서 실행 중

#### Terminal 3: 프론트엔드

```bash
cd /Users/yelim/Desktop/파란학기/frontend
npm run dev
```

✅ 확인: `http://localhost:5173`

---

## API 플로우

### 1. 기본 분석 (1-hop)

```
[프론트엔드]
  사용자가 주소 입력 + 체인 선택 (Ethereum/BSC/Polygon)
  "분석하기" 버튼 클릭
    ↓
  POST /api/analysis/risk-scoring
  {
    "address": "0x...",
    "chain_id": 1,
    "max_hops": 1,
    "analysis_type": "basic"
  }

[백엔드]
  1. Etherscan API로 주소의 거래 내역 조회
  2. 1-hop 그래프 데이터 생성
  3. 거래 데이터를 리스크 스코어링 API 형식으로 변환
    ↓
  POST http://localhost:5001/api/analyze/address
  {
    "address": "0x...",
    "chain_id": 1,
    "transactions": [...],
    "analysis_type": "basic"
  }

[리스크 스코어링 API]
  1. 거래 데이터 분석
  2. 룰 평가 (B-101, D-102 등)
  3. 스코어 계산
  4. 결과 반환
    ↓
  {
    "target_address": "0x...",
    "risk_score": 85,
    "risk_level": "high",
    "fired_rules": [...],
    ...
  }

[백엔드 → 프론트엔드]
  결과를 프론트로 전달
    ↓
[프론트엔드]
  분석 결과 시각화
```

### 2. 심층 분석 (3-hop)

프론트엔드에서 "심층 분석" 버튼 클릭:

```
POST /api/analysis/risk-scoring
{
  "address": "0x...",
  "chain_id": 1,
  "max_hops": 3,  // 3-hop!
  "analysis_type": "advanced"
}
```

백엔드가 3-hop까지 재귀적으로 거래 데이터를 수집하고, 리스크 스코어링 API에 전달합니다.

---

## 테스트

### 1. 헬스 체크

```bash
# 리스크 스코어링 API
curl http://localhost:5001/health

# 백엔드
curl http://localhost:8888/api/dashboard/summary
```

### 2. 주소 분석 테스트

프론트엔드에서:

1. `http://localhost:5173` 접속
2. "Adhoc Analysis" 메뉴 클릭
3. 주소 입력: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb` (예시)
4. 체인 선택: Ethereum
5. "분석하기" 클릭
6. 결과 확인
7. "심층 분석 (3-hop)" 클릭
8. 심층 분석 결과 확인

### 3. API 직접 테스트

```bash
# 백엔드를 통한 리스크 스코어링
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "chain_id": 1,
    "max_hops": 1,
    "analysis_type": "basic"
  }'
```

---

## 트러블슈팅

### 1. 리스크 스코어링 API 연결 실패

**증상**: 백엔드에서 `Risk scoring API call failed` 에러

**원인**: 리스크 스코어링 API가 실행 중이 아니거나 포트가 다름

**해결**:

```bash
# 리스크 스코어링 API 확인
curl http://localhost:5001/health

# 실행 중이 아니면 시작
cd Cryptocurrency-Graphs-of-graphs
source venv/bin/activate
python run_server.py
```

---

### 2. Etherscan API 에러

**증상**: `Scoring analysis failed: ...` 에러

**원인**:

- Etherscan API 키가 설정되지 않음
- API 레이트 리밋 초과

**해결**:

```bash
# API 키 확인
echo $ETHERSCAN_API_KEY

# 설정되지 않았다면
export ETHERSCAN_API_KEY=your_key_here

# 백엔드 재시작
python3 main.py
```

---

### 3. CORS 에러

**증상**: 프론트에서 백엔드 호출 시 CORS 에러

**원인**: 백엔드의 CORS 설정에 프론트 URL이 없음

**해결**: `100end/src/app.py` 확인

```python
CORS(app, origins=["http://localhost:5173", "https://trace-x-two.vercel.app/"])
```

---

### 4. 포트 충돌

**증상**: `Address already in use` 에러

**해결**:

```bash
# 포트 사용 중인 프로세스 찾기
lsof -i :5001  # 리스크 스코어링 API
lsof -i :8888  # 백엔드
lsof -i :5173  # 프론트

# 프로세스 종료
kill -9 <PID>
```

---

### 5. 거래 데이터가 없음

**증상**: 분석 결과가 비어있거나 스코어가 0

**원인**:

- 주소에 거래 내역이 없음
- Etherscan API 호출 실패

**해결**:

- 거래 내역이 있는 주소 사용 (예: 유명 CEX 주소)
- 백엔드 로그 확인

---

## 성공적인 연동 확인 사항

✅ 리스크 스코어링 API 실행 중 (포트 5001)
✅ 백엔드 실행 중 (포트 8888)
✅ 프론트엔드 실행 중 (포트 5173)
✅ Etherscan API 키 설정됨
✅ 주소 입력 후 "분석하기" 클릭 시 결과 표시됨
✅ "심층 분석" 클릭 시 추가 결과 표시됨

---

## 참고 문서

- [백엔드 API 문서](100end/README.md)
- [리스크 스코어링 API 문서](Cryptocurrency-Graphs-of-graphs/README.md)
- [프론트엔드 가이드](frontend/README.md)

---

## 문의

- 백엔드 이슈: 100end 레포지토리
- 리스크 스코어링 이슈: Cryptocurrency-Graphs-of-graphs 레포지토리
- 프론트엔드 이슈: frontend 레포지토리
