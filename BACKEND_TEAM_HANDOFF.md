# 백엔드 팀 전달 문서

## 📋 개요

이 문서는 Trace-X 프로젝트의 배포 및 리스크 스코어링 API 사용 가이드를 백엔드 팀에게 전달하기 위한 것입니다.

---

## 🚨 배포 현황 요약

### 현재 상태

- ✅ **리스크 스코어링 API**: 구현 완료, Docker 이미지 빌드 성공
- ⚠️ **배포**: EC2 서버에서 배포 진행 중 (최종 확인 필요)
- ✅ **통합**: Docker Compose 설정 완료

### 발생한 문제들 (모두 해결됨)

1. ✅ **Python 버전 문제**: `networkx>=3.3` 호환성을 위해 Python 3.10+ 필요 → **해결됨**
2. ✅ **sklearn 모듈 누락**: `scikit-learn>=1.3.0` 의존성 추가 → **해결됨**
3. ✅ **디스크 공간 부족**: EC2 인스턴스 디스크 공간 부족 → **해결됨**
4. ✅ **Healthcheck 문제**: Backend의 healthcheck 엔드포인트 문제 → **해결됨** (`/health` 엔드포인트 추가)
5. ✅ **YAML 문법 오류**: docker-compose.prod.yml 들여쓰기 문제 → **해결됨**

### 배포 확인 필요

EC2 서버에서 다음 명령어로 배포 상태를 확인하세요:

```bash
# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 리스크 스코어링 API healthcheck (EC2 서버에서 테스트)
curl http://localhost:5001/health

# 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring
```

**⚠️ 주의**:

- `curl http://localhost:5001/health`는 **EC2 서버에서 테스트**할 때만 사용합니다
- 백엔드 **코드**에서는 `http://risk-scoring:5001`을 사용해야 합니다

---

## 🔗 리스크 스코어링 API 사용 가이드

### 1. API URL

#### ⚠️ 중요: 백엔드 코드에서 사용할 URL

**백엔드 코드에서 반드시 사용해야 하는 URL:**

```
http://risk-scoring:5001
```

**이유**: Docker Compose는 각 서비스를 별도의 컨테이너로 실행합니다. 컨테이너들은 **내부 네트워크**에서 통신하며, 서비스 이름(`risk-scoring`)을 호스트명으로 사용합니다.

- ✅ **백엔드 코드에서 사용**: `http://risk-scoring:5001` (Docker 내부 네트워크)
- ❌ **백엔드 코드에서 사용하면 안 됨**: `http://localhost:5001` (다른 컨테이너에서는 접근 불가)

#### 📋 URL 사용 가이드

| 용도                         | 사용할 URL                 | 설명                                             |
| ---------------------------- | -------------------------- | ------------------------------------------------ |
| **백엔드 코드에서 API 호출** | `http://risk-scoring:5001` | ✅ **반드시 이 URL 사용** - Docker 내부 네트워크 |
| EC2 서버에서 테스트 (curl)   | `http://localhost:5001`    | 서버 내부에서 healthcheck 테스트용               |
| 브라우저에서 접근            | `http://<EC2-IP>:5001`     | 외부에서 API 문서 확인용                         |

**⚠️ 혼동 주의**:

- `curl http://localhost:5001/health` → EC2 서버에서 **테스트**할 때 사용 (서버 내부)
- 백엔드 **코드**에서는 → `http://risk-scoring:5001` 사용 (Docker 내부 네트워크)

---

### 2. 주요 엔드포인트

#### 2.1 Health Check

```
GET /health
```

**응답 예시:**

```json
{
  "status": "ok",
  "service": "aml-risk-engine"
}
```

#### 2.2 단일 트랜잭션 스코어링

```
POST /api/score/transaction
```

**요청 Body:**

```json
{
  "tx_hash": "0x123...",
  "chain_id": 1,
  "timestamp": "2025-11-23T10:00:00Z",
  "block_height": 21039493,
  "target_address": "0xabc123...",
  "counterparty_address": "0xdef456...",
  "label": "mixer",
  "is_sanctioned": true,
  "is_known_scam": false,
  "is_mixer": true,
  "is_bridge": false,
  "amount_usd": 500000.0,
  "asset_contract": "0xETH"
}
```

**응답 예시:**

```json
{
  "target_address": "0xabc123...",
  "risk_score": 95,
  "risk_level": "critical",
  "risk_tags": ["mixer_inflow", "sanction_exposure"],
  "fired_rules": [
    { "rule_id": "E-101", "score": 25 },
    { "rule_id": "C-001", "score": 30 }
  ],
  "explanation": "...",
  "completed_at": "2025-11-23T10:00:01Z",
  "timestamp": "2025-11-23T10:00:00Z",
  "chain_id": 1,
  "value": 500000.0
}
```

#### 2.3 주소 분석 (다중 트랜잭션)

```
POST /api/analyze/address
```

**요청 Body:**

```json
{
  "address": "0xabc123...",
  "chain_id": 1,
  "transactions": [
    {
      "tx_hash": "0x123...",
      "chain_id": 1,
      "timestamp": "2025-11-23T10:00:00Z",
      "block_height": 21039493,
      "target_address": "0xabc123...",
      "counterparty_address": "0xdef456...",
      "label": "mixer",
      "is_sanctioned": true,
      "is_known_scam": false,
      "is_mixer": true,
      "is_bridge": false,
      "amount_usd": 500000.0,
      "asset_contract": "0xETH"
    }
  ],
  "analysis_type": "basic"
}
```

**파라미터:**

- `analysis_type`: `"basic"` (기본, 빠름) 또는 `"advanced"` (심층 분석, 느림)
- 기본값: `"basic"`

**응답 예시:**

```json
{
  "target_address": "0xabc123...",
  "risk_score": 78,
  "risk_level": "high",
  "risk_tags": ["mixer_inflow", "sanction_exposure"],
  "fired_rules": [
    { "rule_id": "E-101", "score": 25 },
    { "rule_id": "C-001", "score": 30 }
  ],
  "explanation": "...",
  "completed_at": "2025-11-23T10:00:01Z",
  "timestamp": "2025-11-23T10:00:00Z",
  "chain_id": 1,
  "value": 500000.0
}
```

#### 2.4 API 문서 (Swagger UI)

```
GET /api-docs
```

브라우저에서 접속하면 Swagger UI로 인터랙티브 API 문서를 확인할 수 있습니다.

---

### 3. 백엔드에서 API 호출 예시

#### Python (requests 사용)

```python
import requests
import os

# API URL 설정
RISK_SCORING_API_URL = os.getenv(
    "RISK_SCORING_API_URL",
    "http://risk-scoring:5001"  # Docker Compose 내부 네트워크
)

# 단일 트랜잭션 스코어링
def score_transaction(tx_data: dict) -> dict:
    response = requests.post(
        f"{RISK_SCORING_API_URL}/api/score/transaction",
        json=tx_data,
        timeout=30
    )
    response.raise_for_status()
    return response.json()

# 주소 분석
def analyze_address(address: str, transactions: list, analysis_type: str = "basic") -> dict:
    response = requests.post(
        f"{RISK_SCORING_API_URL}/api/analyze/address",
        json={
            "address": address,
            "chain_id": 1,
            "transactions": transactions,
            "analysis_type": analysis_type
        },
        timeout=60  # advanced 분석은 시간이 더 걸릴 수 있음
    )
    response.raise_for_status()
    return response.json()

# Health check
def check_risk_scoring_health() -> bool:
    try:
        response = requests.get(f"{RISK_SCORING_API_URL}/health", timeout=5)
        return response.status_code == 200
    except Exception:
        return False
```

#### 현재 백엔드 코드 확인 및 수정 필요

현재 `trace-x/backend/src/api/risk_scoring.py` 파일을 확인해보세요:

```python
# 현재 코드 (14번 줄 근처) - 수정 필요!
RISK_SCORING_API_URL = "http://localhost:5001"  # ❌ Docker Compose에서는 작동 안 함
```

**⚠️ 문제**: 이 코드는 Docker Compose 환경에서 작동하지 않습니다! **반드시 수정**이 필요합니다.

**수정 방법:**

```python
# 환경 변수로 설정 (권장)
import os

RISK_SCORING_API_URL = os.getenv(
    "RISK_SCORING_API_URL",
    "http://risk-scoring:5001"  # ✅ Docker Compose 기본값
)
```

그리고 `.env` 파일에 추가:

```bash
# .env 파일
RISK_SCORING_API_URL=http://risk-scoring:5001
```

**왜 `risk-scoring:5001`을 사용해야 하나요?**

- Docker Compose는 각 서비스를 별도 컨테이너로 실행
- 컨테이너 간 통신은 **내부 네트워크**에서 서비스 이름으로 이루어짐
- `localhost`는 같은 컨테이너 내에서만 작동하므로, 다른 컨테이너(backend)에서는 접근 불가
- `risk-scoring`은 Docker Compose가 자동으로 DNS로 해석해주는 서비스 이름

---

### 4. 환경 변수 설정

#### Docker Compose 환경 변수 (프로덕션/통합 배포)

`trace-x/.env` 파일에 다음을 추가:

```bash
RISK_SCORING_API_URL=http://risk-scoring:5001
```

**⚠️ 중요**:

- Docker Compose 내부 네트워크에서는 **반드시** `risk-scoring` (서비스 이름)을 사용해야 합니다
- `localhost`는 같은 컨테이너 내에서만 작동하므로 다른 컨테이너(backend)에서는 접근할 수 없습니다

#### 로컬 개발 환경 (Docker 없이 실행)

```bash
export RISK_SCORING_API_URL=http://localhost:5001
```

**언제 사용하나요?**

- 로컬에서 Docker 없이 직접 `python main.py`로 실행하는 경우만
- 대부분의 경우 Docker Compose를 사용하므로 `http://risk-scoring:5001`을 사용하세요

---

### 5. API 호출 주의사항

#### 타임아웃 설정

- **기본 분석 (`analysis_type: "basic"`)**: 30초 타임아웃 권장
- **심층 분석 (`analysis_type: "advanced"`)**: 60초 이상 타임아웃 권장

#### 에러 처리

```python
try:
    result = score_transaction(tx_data)
except requests.exceptions.Timeout:
    # 타임아웃 처리
    pass
except requests.exceptions.RequestException as e:
    # 네트워크 에러 처리
    pass
except ValueError as e:
    # 응답 파싱 에러 처리
    pass
```

#### 응답 코드

- `200`: 성공
- `400`: 잘못된 요청 (필수 파라미터 누락 등)
- `500`: 서버 내부 에러

---

## 📦 배포 가이드

### Docker Compose 사용 (권장)

현재 프로젝트는 Docker Compose를 사용하여 통합 배포됩니다.

#### 파일 구조

```
trace-x/
├── docker-compose.prod.yml  # 프로덕션 배포 설정
├── risk-scoring/            # 리스크 스코어링 API
├── backend/                 # 백엔드 API
└── frontend/                # 프론트엔드
```

#### 배포 명령어

```bash
cd ~/trace-x

# 최신 코드 가져오기
git pull origin main

# 서비스 시작
docker-compose -f docker-compose.prod.yml up -d

# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f

# 서비스 중지
docker-compose -f docker-compose.prod.yml down
```

#### 서비스 포트

- **리스크 스코어링 API**: `http://localhost:5001`
- **백엔드 API**: `http://localhost:8888`
- **프론트엔드**: `http://localhost:5173`

**⚠️ 주의**: Docker Compose 내부 네트워크에서는 위의 포트가 아닌 서비스 이름을 사용합니다:

- `http://risk-scoring:5001`
- `http://backend:8888`
- `http://frontend:80`

---

### 수동 배포 (Docker Compose 없이)

#### 리스크 스코어링 API만 배포

```bash
cd trace-x/risk-scoring

# Docker 이미지 빌드
docker build -t trace-x-risk-scoring .

# 컨테이너 실행
docker run -d \
  --name trace-x-risk-scoring \
  -p 5001:5001 \
  trace-x-risk-scoring
```

#### 백엔드에서 연결

환경 변수 설정:

```bash
export RISK_SCORING_API_URL=http://localhost:5001
# 또는 EC2 서버의 경우
export RISK_SCORING_API_URL=http://<EC2-PUBLIC-IP>:5001
```

---

## 🔍 문제 해결 가이드

### 리스크 스코어링 API 연결 실패

#### 문제: Connection refused

**원인**: API 서버가 실행되지 않음

**해결**:

```bash
# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps risk-scoring

# 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring

# 서비스 재시작
docker-compose -f docker-compose.prod.yml restart risk-scoring
```

#### 문제: Timeout

**원인**: 분석 시간이 오래 걸림

**해결**:

- 타임아웃 시간 증가 (60초 이상)
- `analysis_type`을 `"basic"`으로 변경

#### 문제: 500 Internal Server Error

**원인**: API 서버 내부 에러

**해결**:

```bash
# 로그 확인
docker-compose -f docker-compose.prod.yml logs risk-scoring

# 특정 에러 검색
docker-compose -f docker-compose.prod.yml logs risk-scoring | grep -i error
```

---

## 📚 추가 문서

### 리스크 스코어링 API 상세 문서

- **API 문서**: `trace-x/risk-scoring/docs/API_DOCUMENTATION.md`
- **입출력 명세**: `trace-x/risk-scoring/docs/RISK_SCORING_IO.md`
- **배포 가이드**: `trace-x/risk-scoring/docs/DEPLOYMENT_GUIDE.md`

### 통합 배포 문서

- **빠른 배포 가이드**: `trace-x/QUICK_DEPLOY.md`
- **전체 배포 가이드**: `trace-x/docs/DEPLOYMENT.md`
- **EC2 배포 가이드**: `trace-x/EC2_NEW_INSTANCE.md`

### 문제 해결 문서

- **디스크 공간 부족**: `trace-x/FIX_DISK_SPACE.md`
- **Healthcheck 문제**: `trace-x/FIX_BACKEND_UNHEALTHY.md`
- **Python 버전 문제**: `trace-x/FIX_PYTHON_VERSION.md`

---

## 📞 문의 사항

### 리스크 스코어링 API 관련

- **저장소**: https://github.com/paran-needless-to-say/aml-risk-engine2
- **API 문서**: http://localhost:5001/api-docs (서버 실행 후)

### 통합 배포 관련

- **저장소**: https://github.com/paran-needless-to-say/integration
- **문서**: `trace-x/` 디렉토리 내 문서 참고

---

## ✅ 체크리스트

백엔드 팀이 확인해야 할 사항:

- [ ] 리스크 스코어링 API URL 확인 (`http://risk-scoring:5001` 또는 `http://localhost:5001`)
- [ ] API 엔드포인트 테스트 (`/health`, `/api/score/transaction`)
- [ ] 환경 변수 설정 확인 (`RISK_SCORING_API_URL`)
- [ ] 타임아웃 설정 확인 (30-60초)
- [ ] 에러 처리 구현 확인
- [ ] Docker Compose 내부 네트워크 연결 확인

---

**마지막 업데이트**: 2025-11-23

**작성자**: Trace-X 팀
