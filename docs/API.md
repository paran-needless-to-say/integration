# 📡 Trace-X API 사용 가이드

Trace-X 플랫폼의 모든 API 엔드포인트와 사용 방법을 설명합니다.

---

## 📋 목차

1. [API 개요](#api-개요)
2. [Backend API](#backend-api)
3. [Risk Scoring API](#risk-scoring-api)
4. [API 플로우 예시](#api-플로우-예시)
5. [에러 처리](#에러-처리)
6. [성능 고려사항](#성능-고려사항)

---

## 🎯 API 개요

Trace-X는 **3-tier 아키텍처**로 구성되어 있으며, 각 레이어별로 API가 제공됩니다:

```
Frontend (5173) → Backend (8888) → Risk Scoring API (5001)
```

### Base URLs

| 서비스 | Base URL | 설명 |
|--------|----------|------|
| **Backend** | `http://localhost:8888` | 메인 API 서버 |
| **Risk Scoring API** | `http://localhost:5001` | 리스크 스코어링 전용 API |
| **Frontend** | `http://localhost:5173` | 웹 인터페이스 |

---

## 🔧 Backend API

### Base URL: `http://localhost:8888`

### 1. 리스크 스코어링 분석 ⭐

**주소 기반 리스크 스코어링 (통합 엔드포인트)**

#### 엔드포인트

```
POST /api/analysis/risk-scoring
GET  /api/analysis/risk-scoring
```

#### 요청 (POST)

```http
POST /api/analysis/risk-scoring
Content-Type: application/json

{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "chain_id": 1,
  "max_hops": 3,
  "max_addresses_per_direction": 10,
  "analysis_type": "basic"
}
```

#### 요청 (GET)

```http
GET /api/analysis/risk-scoring?chain_id=1&address=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb&hop_count=3&analysis_type=basic
```

#### 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `address` | string | ✅ | - | 분석할 주소 (0x로 시작) |
| `chain_id` | integer | ✅ | - | 체인 ID (1=Ethereum, 56=BSC, 137=Polygon) |
| `max_hops` | integer | ❌ | 3 | 최대 홉 수 (1~5 권장) |
| `hop_count` | integer | ❌ | 3 | `max_hops`와 동일 (호환성) |
| `max_addresses_per_direction` | integer | ❌ | 10 | 방향당 최대 주소 수 |
| `analysis_type` | string | ❌ | "basic" | "basic" 또는 "advanced" |

#### 응답

```json
{
  "data": {
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "chain": "ethereum",
    "chain_id": 1,
    "final_score": 85,
    "risk_level": "high",
    "risk_tags": ["sanction_exposure", "large_amount", "mixer_pattern"],
    "fired_rules": [
      {
        "rule_id": "C-001",
        "score": 30,
        "description": "Sanctioned address exposure"
      },
      {
        "rule_id": "E-101",
        "score": 25,
        "description": "Large transaction amount (>$100k)"
      },
      {
        "rule_id": "B-201",
        "score": 30,
        "description": "Mixer pattern detected"
      }
    ],
    "explanation": "High risk due to sanctioned address exposure and large transaction amounts. Mixer pattern detected in transaction history.",
    "completed_at": "2025-01-15T10:30:00Z",
    "timestamp": "2025-01-15T10:30:00Z",
    "value": 500000.0
  }
}
```

#### cURL 예시

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

#### JavaScript 예시

```javascript
const response = await fetch('http://localhost:8888/api/analysis/risk-scoring', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    address: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    chain_id: 1,
    max_hops: 3,
    analysis_type: 'basic'
  })
});

const result = await response.json();
console.log(`Risk Score: ${result.data.final_score}`);
console.log(`Risk Level: ${result.data.risk_level}`);
```

#### Python 예시

```python
import requests

url = "http://localhost:8888/api/analysis/risk-scoring"
payload = {
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "chain_id": 1,
    "max_hops": 3,
    "analysis_type": "basic"
}

response = requests.post(url, json=payload)
result = response.json()

print(f"Risk Score: {result['data']['final_score']}")
print(f"Risk Level: {result['data']['risk_level']}")
```

---

### 2. Fund Flow 분석

**거래 그래프 데이터 조회**

#### 엔드포인트

```
GET /api/analysis/fund-flow
```

#### 요청

```http
GET /api/analysis/fund-flow?chain_id=1&address=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb&max_hops=2&max_addresses=10
```

#### 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `address` | string | ✅ | - | 분석할 주소 |
| `chain_id` | integer | ✅ | - | 체인 ID |
| `max_hops` | integer | ❌ | 2 | 최대 홉 수 |
| `max_addresses` | integer | ❌ | 10 | 방향당 최대 주소 수 |

#### 응답

```json
{
  "data": {
    "nodes": [
      {
        "address": "0x742d35...",
        "label": "Target Address",
        "usd_value": 1000000.0
      },
      {
        "address": "0xdef456...",
        "label": "Counterparty",
        "usd_value": 500000.0
      }
    ],
    "edges": [
      {
        "from_address": "0x742d35...",
        "to_address": "0xdef456...",
        "tx_hash": "0xabc123...",
        "usd_value": 500000.0,
        "tx_type": "transfer",
        "timestamp": 1705315200,
        "block_height": 21039493
      }
    ]
  }
}
```

---

### 3. Transaction Flow 분석

**트랜잭션 해시 기반 자금 흐름 분석**

#### 엔드포인트

```
GET /api/analysis/transaction-flow
```

#### 요청

```http
GET /api/analysis/transaction-flow?chain_id=1&tx_hash=0xabc123...&max_hops=3
```

#### 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `tx_hash` | string | ✅ | - | 트랜잭션 해시 |
| `chain_id` | integer | ✅ | - | 체인 ID |
| `max_hops` | integer | ❌ | 3 | 최대 홉 수 |

---

### 4. Bridge 분석

**브리지 트랜잭션 분석**

#### 엔드포인트

```
GET /api/analysis/bridge
```

#### 요청

```http
GET /api/analysis/bridge?chain_id=1&tx_hash=0xabc123...
```

#### 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `tx_hash` | string | ✅ | - | 브리지 트랜잭션 해시 |
| `chain_id` | integer | ✅ | - | 체인 ID |

---

### 5. Dashboard API

#### 엔드포인트

```
GET /api/dashboard/summary
GET /api/dashboard/monitoring
```

---

### 6. Live Detection API

#### 엔드포인트

```
GET /api/live-detection/summary
```

#### 요청

```http
GET /api/live-detection/summary?tokenFilter=USDT&pageNo=1
```

---

## 📊 Risk Scoring API

### Base URL: `http://localhost:5001`

리스크 스코어링 API는 백엔드를 통해 간접 호출하는 것을 권장합니다. 직접 호출이 필요한 경우 아래 엔드포인트를 사용할 수 있습니다.

### 1. 주소 분석

#### 엔드포인트

```
POST /api/analyze/address
```

#### 요청

```json
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "chain_id": 1,
  "transactions": [
    {
      "tx_hash": "0xabc123...",
      "chain_id": 1,
      "timestamp": "2025-01-15T10:00:00Z",
      "block_height": 21039493,
      "from": "0x742d35...",
      "to": "0xdef456...",
      "target_address": "0x742d35...",
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

#### 응답

```json
{
  "target_address": "0x742d35...",
  "chain": "ethereum",
  "chain_id": 1,
  "final_score": 85,
  "risk_level": "high",
  "risk_tags": ["sanction_exposure", "mixer_pattern"],
  "fired_rules": [
    {
      "rule_id": "C-001",
      "score": 30,
      "description": "Sanctioned address exposure"
    },
    {
      "rule_id": "B-201",
      "score": 30,
      "description": "Mixer pattern detected"
    }
  ],
  "explanation": "High risk due to sanctioned address exposure...",
  "completed_at": "2025-01-15T10:30:00Z",
  "timestamp": "2025-01-15T10:30:00Z",
  "value": 500000.0
}
```

---

## 🔄 API 플로우 예시

### 예시 1: 기본 분석 (1-hop)

```
1. Frontend → Backend
   POST /api/analysis/risk-scoring
   {
     "address": "0x742d35...",
     "chain_id": 1,
     "max_hops": 1,
     "analysis_type": "basic"
   }

2. Backend → Risk Scoring API
   POST http://localhost:5001/api/analyze/address
   {
     "address": "0x742d35...",
     "chain_id": 1,
     "transactions": [...],  // 1-hop 거래 데이터
     "analysis_type": "basic"
   }

3. Risk Scoring API → Backend
   {
     "final_score": 45,
     "risk_level": "medium-high",
     ...
   }

4. Backend → Frontend
   {
     "data": {
       "final_score": 45,
       "risk_level": "medium-high",
       ...
     }
   }
```

### 예시 2: 심층 분석 (3-hop, advanced)

```
1. Frontend → Backend
   POST /api/analysis/risk-scoring
   {
     "address": "0x742d35...",
     "chain_id": 1,
     "max_hops": 3,
     "analysis_type": "advanced"
   }

2. Backend: Multi-hop 데이터 수집
   - 1-hop: 직접 거래
   - 2-hop: 1단계 상대방과의 거래
   - 3-hop: 2단계 상대방과의 거래
   - 그래프 데이터 생성

3. Backend → Risk Scoring API
   POST http://localhost:5001/api/analyze/address
   {
     "address": "0x742d35...",
     "chain_id": 1,
     "transactions": [...],  // 3-hop 거래 데이터 (더 많음)
     "analysis_type": "advanced"  // 그래프 패턴 탐지 포함
   }

4. Risk Scoring API: 심층 분석
   - 룰 평가
   - 그래프 패턴 탐지 (Layering Chain, Cycle 등)
   - 점수 계산

5. Risk Scoring API → Backend → Frontend
   {
     "final_score": 85,
     "risk_level": "high",
     "fired_rules": [...],
     "graph_patterns": [...]
   }
```

---

## ⚠️ 에러 처리

### 에러 응답 형식

```json
{
  "error": "Error message description"
}
```

### 일반적인 에러 코드

| HTTP 상태 코드 | 설명 | 해결 방법 |
|---------------|------|----------|
| 400 | Bad Request | 요청 파라미터 확인 |
| 404 | Not Found | 엔드포인트 경로 확인 |
| 500 | Internal Server Error | 서버 로그 확인 |

### 에러 예시

#### 1. 필수 파라미터 누락

```json
{
  "error": "chain_id is required"
}
```

**해결**: `chain_id` 파라미터 제공

#### 2. 잘못된 파라미터 타입

```json
{
  "error": "chain_id must be a valid integer"
}
```

**해결**: `chain_id`를 정수로 제공

#### 3. 리스크 스코어링 API 연결 실패

```json
{
  "error": "Risk scoring failed: Risk scoring API call failed: Connection refused"
}
```

**해결**: 리스크 스코어링 API 실행 확인 (`http://localhost:5001/health`)

#### 4. Etherscan API 에러

```json
{
  "error": "Analysis failed: Etherscan API error: Rate limit exceeded"
}
```

**해결**: 
- Etherscan API 키 확인
- Rate limit 대기 또는 유료 API 키 사용

---

## 📈 성능 고려사항

### 응답 시간

| 분석 타입 | Hop 수 | 예상 시간 | 권장 사용 |
|----------|--------|----------|----------|
| 기본 분석 | 1-hop | ~5초 | 실시간 대시보드 |
| 심층 분석 | 3-hop | ~15-30초 | 상세 분석 요청 |

### 최적화 팁

1. **1-hop 기본 분석 사용**: 빠른 응답이 필요한 경우
2. **캐싱 활용**: 동일 주소 재분석 시 (향후 구현)
3. **비동기 처리**: 프론트엔드에서 비동기 API 호출
4. **Rate Limit 고려**: Etherscan API 무료 계정: 초당 5 요청

### Rate Limit

| API | Rate Limit | 권장 |
|-----|------------|------|
| Etherscan (무료) | 5 req/sec | 개발/테스트용 |
| Etherscan (Pro) | 50 req/sec | 프로덕션 권장 |

---

## 📚 체인 ID 참조

| 체인 | Chain ID | 지원 여부 |
|------|----------|----------|
| Ethereum | 1 | ✅ |
| BSC (Binance Smart Chain) | 56 | ✅ |
| Polygon | 137 | ✅ |
| Arbitrum | 42161 | ⚠️ (준비 중) |

---

## 🧪 테스트 예시

### cURL 테스트

```bash
# 기본 분석 (1-hop)
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
    "chain_id": 1,
    "max_hops": 1,
    "analysis_type": "basic"
  }'

# 심층 분석 (3-hop)
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
    "chain_id": 1,
    "max_hops": 3,
    "analysis_type": "advanced"
  }'
```

### JavaScript 테스트

```javascript
// 브라우저 콘솔에서 실행
const testRiskScoring = async () => {
  try {
    const response = await fetch('http://localhost:8888/api/analysis/risk-scoring', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        address: '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be',
        chain_id: 1,
        max_hops: 1,
        analysis_type: 'basic'
      })
    });
    
    const result = await response.json();
    console.log('Risk Score:', result.data.final_score);
    console.log('Risk Level:', result.data.risk_level);
    console.log('Fired Rules:', result.data.fired_rules);
  } catch (error) {
    console.error('Error:', error);
  }
};

testRiskScoring();
```

### Python 테스트

```python
import requests
import json

def test_risk_scoring():
    url = "http://localhost:8888/api/analysis/risk-scoring"
    payload = {
        "address": "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
        "chain_id": 1,
        "max_hops": 1,
        "analysis_type": "basic"
    }
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        result = response.json()
        
        print(f"Risk Score: {result['data']['final_score']}")
        print(f"Risk Level: {result['data']['risk_level']}")
        print(f"Fired Rules: {len(result['data']['fired_rules'])}")
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_risk_scoring()
```

---

## 📖 관련 문서

- [시스템 아키텍처](ARCHITECTURE.md) - 전체 시스템 구조 설명
- [핵심 로직 가이드](CORE_LOGIC.md) - 데이터 플로우 및 로직 상세 설명
- [통합 가이드](INTEGRATION_GUIDE.md) - 통합 설정 및 실행 가이드

---

**Made with ❤️ by the Trace-X Team**

