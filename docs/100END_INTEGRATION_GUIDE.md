# 🔗 100end 폴더 통합 가이드

백엔드 팀을 위한 리스크 스코어링 API 연동 통합 가이드입니다.

---

## 📋 목차

1. [통합 개요](#통합-개요)
2. [필요한 파일](#필요한-파일)
3. [설치 및 설정](#설치-및-설정)
4. [코드 변경 사항](#코드-변경-사항)
5. [API 사용 방법](#api-사용-방법)
6. [테스트](#테스트)
7. [배포](#배포)

---

## 📝 통합 개요

### 동작 방식

```
1. 프론트에서 주소 입력
   ↓
2. 백엔드에서 Etherscan API 호출
   ↓
3. 그래프 데이터 생성: {nodes: [...], edges: [...]}
   ↓
4. 거래 배열 변환: [{tx_hash, from, to, amount_usd, ...}, ...]
   ↓
5. 리스크 스코어링 API 호출 (http://localhost:5001/api/analyze/address)
   ↓
6. 결과 반환: {risk_score, risk_level, fired_rules, ...}
```

### 역할 분담

- **백엔드 (100end)**: 데이터 수집, 그래프 생성, 데이터 변환, API 호출
- **리스크 스코어링 API**: 룰 평가, 점수 계산, 패턴 탐지

---

## 📁 필요한 파일

### 1. 새로 추가할 파일

#### `src/api/risk_scoring.py`

리스크 스코어링 API 연동 모듈

- 그래프 데이터 → 거래 배열 변환
- 리스크 스코어링 API 호출
- SDN 리스트 체크

### 2. 수정할 파일

#### `src/app.py`

리스크 스코어링 엔드포인트 추가

- `/api/analysis/risk-scoring` 엔드포인트 추가

#### `pyproject.toml` (또는 `requirements.txt`)

의존성 추가

- `requests>=2.28.0` 추가

---

## 🔧 설치 및 설정

### 1. 의존성 추가

#### `pyproject.toml`에 추가

```toml
dependencies = [
    # ... 기존 의존성 ...
    "requests>=2.28.0",  # 리스크 스코어링 API 호출용
]
```

또는 `requirements.txt`에 추가:

```txt
requests>=2.28.0
```

### 2. 리스크 스코어링 API URL 설정

#### 환경 변수 (권장)

```bash
export RISK_SCORING_API_URL=http://localhost:5001
```

또는 `risk_scoring.py`에서 직접 설정:

```python
RISK_SCORING_API_URL = "http://localhost:5001"  # EC2 배포 시 실제 URL로 변경
```

**EC2 배포 시**:

- 같은 서버에서 실행: `http://localhost:5001`
- 별도 서버에서 실행: `http://<리스크-스코어링-서버-IP>:5001`

---

## 📝 코드 변경 사항

### 1. `src/app.py` 수정

#### import 추가

```python
from src.api.risk_scoring import analyze_address_with_risk_scoring
```

#### 엔드포인트 추가

```python
@app.route('/api/analysis/risk-scoring', methods=['GET', 'POST'])
def get_risk_scoring_analysis():
    """
    Multi-hop 데이터 수집 + 리스크 스코어링

    GET Request:
        /api/analysis/risk-scoring?chain_id=1&address=0x...&hop_count=3

    POST Request:
    {
        "address": "0x...",
        "chain_id": 1,
        "max_hops": 3,  // optional, default: 3
        "analysis_type": "basic" or "advanced"  // optional, default: "basic"
    }
    """
    # GET 또는 POST 파라미터 처리
    if request.method == 'GET':
        chain_id = request.args.get('chain_id')
        address = request.args.get('address')
        hop_count = request.args.get('hop_count', '3')
        max_hops = hop_count
        max_addresses_per_direction = request.args.get('max_addresses_per_direction', '10')
        analysis_type = request.args.get('analysis_type', 'basic')
    else:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400

        chain_id = data.get('chain_id')
        address = data.get('address')
        max_hops = data.get('max_hops', data.get('hop_count', 3))
        max_addresses_per_direction = data.get('max_addresses_per_direction', 10)
        analysis_type = data.get('analysis_type', 'basic')

    if not chain_id:
        return jsonify({'error': 'chain_id is required'}), 400

    if not address:
        return jsonify({'error': 'address is required'}), 400

    if analysis_type not in ['basic', 'advanced']:
        return jsonify({'error': 'analysis_type must be "basic" or "advanced"'}), 400

    try:
        chain_id = int(chain_id)
        max_hops = int(max_hops)
        max_addresses_per_direction = int(max_addresses_per_direction)
    except (ValueError, TypeError):
        return jsonify({'error': 'chain_id, max_hops/hop_count, and max_addresses_per_direction must be valid integers'}), 400

    try:
        # 1. Multi-hop 그래프 데이터 수집
        analyzer = current_app.analyzer
        graph_data = analyzer.get_multihop_fund_flow_for_scoring(
            chain_id=chain_id,
            address=address,
            max_hops=max_hops,
            max_addresses_per_direction=max_addresses_per_direction
        )

        # 2. 리스크 스코어링 API 호출
        result = analyze_address_with_risk_scoring(
            address=address,
            chain_id=chain_id,
            graph_data=graph_data,
            analysis_type=analysis_type
        )

        return jsonify({'data': result}), 200
    except Exception as e:
        return jsonify({'error': f'Risk scoring failed: {str(e)}'}), 500
```

### 2. `src/api/risk_scoring.py` 파일 생성

전체 파일 내용은 다음 섹션 참고.

---

## 📄 `src/api/risk_scoring.py` 전체 코드

```python
"""
리스크 스코어링 API 연동 모듈

백엔드에서 거래 데이터를 수집하고 리스크 스코어링 API에 전달
"""
import requests
import json
from typing import Dict, Any, List, Set
from datetime import datetime
import os


# 리스크 스코어링 API URL
RISK_SCORING_API_URL = os.getenv('RISK_SCORING_API_URL', 'http://localhost:5001')

# SDN 리스트 로드 (선택사항)
def load_sdn_list() -> Set[str]:
    """SDN 리스트 로드"""
    try:
        # SDN 리스트 경로 설정 (백엔드 팀의 실제 경로로 변경 필요)
        # 현재는 빈 Set 반환 (리스크 스코어링 API에서 처리하도록)
        return set()
    except Exception as e:
        print(f"Warning: Failed to load SDN list: {e}")
        return set()

# SDN 리스트 캐시 (앱 시작 시 한 번만 로드)
SDN_LIST = load_sdn_list()
if SDN_LIST:
    print(f"✅ SDN 리스트 로드 완료: {len(SDN_LIST)}개 주소")


def convert_graph_to_transactions(graph_data: Dict[str, Any], target_address: str) -> List[Dict[str, Any]]:
    """
    백엔드의 그래프 데이터를 리스크 스코어링 API 형식으로 변환

    Args:
        graph_data: 백엔드 그래프 데이터 (nodes, edges)
        target_address: 분석 대상 주소

    Returns:
        리스크 스코어링 API 형식의 거래 배열
    """
    transactions = []
    edges = graph_data.get('edges', [])

    for edge in edges:
        # 거래 데이터 변환
        from_addr = edge.get('from_address', '').lower()
        to_addr = edge.get('to_address', '').lower()

        # SDN 리스트 체크: from 또는 to가 SDN 리스트에 있는지 확인
        is_sanctioned = from_addr in SDN_LIST or to_addr in SDN_LIST

        tx = {
            "tx_hash": edge.get('tx_hash', ''),
            "chain_id": edge.get('chain_id', 1),
            "timestamp": convert_timestamp(edge.get('timestamp', '')),
            "block_height": edge.get('block_height', 0),
            "from": from_addr,
            "to": to_addr,
            "target_address": target_address.lower(),
            "counterparty_address": get_counterparty(edge, target_address),
            "label": infer_label(edge),
            "is_sanctioned": is_sanctioned,
            "is_known_scam": False,  # TODO: 사기 리스트 체크 (추후 구현)
            "is_mixer": False,  # TODO: 믹서 리스트 체크 (추후 구현)
            "is_bridge": edge.get('tx_type', '') == 'bridge',
            "amount_usd": float(edge.get('usd_value', 0)),
            "asset_contract": edge.get('token_address', '0xETH')
        }

        transactions.append(tx)

    return transactions


def convert_timestamp(timestamp: str) -> str:
    """
    Unix timestamp를 ISO8601 형식으로 변환

    Args:
        timestamp: Unix timestamp (문자열 또는 숫자)

    Returns:
        ISO8601 UTC 형식 문자열
    """
    try:
        if isinstance(timestamp, str):
            timestamp = int(timestamp)
        dt = datetime.fromtimestamp(timestamp)
        return dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    except:
        return "2025-01-01T00:00:00Z"


def get_counterparty(edge: Dict[str, Any], target_address: str) -> str:
    """
    상대방 주소 추출

    Args:
        edge: 거래 edge 데이터
        target_address: 분석 대상 주소

    Returns:
        counterparty 주소
    """
    from_addr = edge.get('from_address', '').lower()
    to_addr = edge.get('to_address', '').lower()
    target = target_address.lower()

    if from_addr == target:
        return to_addr
    else:
        return from_addr


def infer_label(edge: Dict[str, Any]) -> str:
    """
    거래 타입에서 라벨 추론

    Args:
        edge: 거래 edge 데이터

    Returns:
        "mixer" | "bridge" | "cex" | "dex" | "defi" | "unknown"
    """
    tx_type = edge.get('tx_type', '')

    if tx_type == 'bridge':
        return 'bridge'
    elif tx_type == 'swap':
        return 'dex'
    else:
        return 'unknown'


def call_risk_scoring_api(
    address: str,
    chain_id: int,
    transactions: List[Dict[str, Any]],
    analysis_type: str = "basic"
) -> Dict[str, Any]:
    """
    리스크 스코어링 API 호출

    Args:
        address: 분석 대상 주소
        chain_id: 체인 ID
        transactions: 거래 배열
        analysis_type: "basic" 또는 "advanced"

    Returns:
        리스크 스코어링 결과
    """
    url = f"{RISK_SCORING_API_URL}/api/analyze/address"

    payload = {
        "address": address,
        "chain_id": chain_id,
        "transactions": transactions,
        "analysis_type": analysis_type
    }

    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        raise Exception(f"Risk scoring API call failed: {str(e)}")


def analyze_address_with_risk_scoring(
    address: str,
    chain_id: int,
    graph_data: Dict[str, Any],
    analysis_type: str = "basic"
) -> Dict[str, Any]:
    """
    주소 분석 + 리스크 스코어링

    Args:
        address: 분석 대상 주소
        chain_id: 체인 ID
        graph_data: 백엔드 그래프 데이터
        analysis_type: "basic" 또는 "advanced"

    Returns:
        리스크 스코어링 결과
    """
    # 1. 그래프 데이터를 거래 배열로 변환
    transactions = convert_graph_to_transactions(graph_data, address)

    # 2. 리스크 스코어링 API 호출
    result = call_risk_scoring_api(address, chain_id, transactions, analysis_type)

    return result
```

---

## 🔌 API 사용 방법

### 엔드포인트

```
GET /api/analysis/risk-scoring
POST /api/analysis/risk-scoring
```

### GET 요청 예시

```bash
curl "http://localhost:8888/api/analysis/risk-scoring?chain_id=1&address=0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be&hop_count=3&analysis_type=basic"
```

**Query Parameters:**

- `chain_id` (required): 체인 ID (1 = Ethereum)
- `address` (required): 분석할 주소
- `hop_count` (optional): 최대 홉 수 (기본값: 3)
- `max_addresses_per_direction` (optional): 방향당 최대 주소 수 (기본값: 10)
- `analysis_type` (optional): "basic" 또는 "advanced" (기본값: "basic")

### POST 요청 예시

```bash
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d '{
    "chain_id": 1,
    "address": "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
    "max_hops": 3,
    "max_addresses_per_direction": 10,
    "analysis_type": "basic"
  }'
```

### 응답 예시

```json
{
  "data": {
    "address": "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
    "chain": "ethereum",
    "final_score": 85,
    "risk_level": "high",
    "risk_tags": ["sanction_exposure", "large_amount"],
    "fired_rules": [
      {
        "rule_id": "C-001",
        "score": 30,
        "description": "Sanctioned address exposure"
      },
      {
        "rule_id": "E-101",
        "score": 25,
        "description": "Large transaction amount"
      }
    ],
    "explanation": "High risk due to sanctioned address exposure and large transaction amounts.",
    "completed_at": "2025-01-15T10:30:00Z",
    "timestamp": "2025-01-15T10:30:00Z",
    "chain_id": 1,
    "value": 500000.0
  }
}
```

---

## 🧪 테스트

### 1. 리스크 스코어링 API 확인

```bash
# Health check
curl http://localhost:5001/health

# API 문서 확인
open http://localhost:5001/api-docs
```

### 2. 백엔드 API 테스트

```bash
# 테스트 주소 (Binance Hot Wallet)
ADDRESS="0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be"

# GET 요청
curl "http://localhost:8888/api/analysis/risk-scoring?chain_id=1&address=${ADDRESS}&hop_count=2"

# POST 요청
curl -X POST http://localhost:8888/api/analysis/risk-scoring \
  -H "Content-Type: application/json" \
  -d "{
    \"chain_id\": 1,
    \"address\": \"${ADDRESS}\",
    \"max_hops\": 2,
    \"analysis_type\": \"basic\"
  }"
```

---

## 🚀 배포

### 1. 리스크 스코어링 API 배포

리스크 스코어링 API가 먼저 실행되어야 합니다.

```bash
# 리스크 스코어링 API 실행
cd risk-scoring  # 또는 실제 경로
python run_server.py
```

**포트**: 5001

### 2. 백엔드 환경 변수 설정

#### EC2에서 실행 시

```bash
# .env 파일 또는 환경 변수 설정
export ETHERSCAN_API_KEY=your_etherscan_api_key
export RISK_SCORING_API_URL=http://localhost:5001  # 또는 실제 서버 URL
```

#### 같은 서버에서 실행

- `RISK_SCORING_API_URL=http://localhost:5001`

#### 별도 서버에서 실행

- `RISK_SCORING_API_URL=http://<리스크-스코어링-서버-IP>:5001`

### 3. 백엔드 실행

```bash
cd 100end  # 또는 실제 백엔드 경로
pip3 install -e .
python3 main.py
```

**포트**: 8888

### 4. EC2 재시작

백엔드 팀의 EC2 재시작 프로세스에 따라 재시작하시면 됩니다.

---

## ⚠️ 주의사항

1. **리스크 스코어링 API 먼저 실행**: 백엔드가 리스크 스코어링 API를 호출하므로, 리스크 스코어링 API가 먼저 실행되어야 합니다.

2. **API URL 설정**: EC2 배포 시 `RISK_SCORING_API_URL` 환경 변수를 올바르게 설정해야 합니다.

3. **포트 충돌**: 리스크 스코어링 API가 5001 포트를 사용하므로, 해당 포트가 열려있어야 합니다.

4. **의존성 설치**: `requests` 패키지가 설치되어 있어야 합니다.

5. **SDN 리스트**: 현재는 SDN 리스트를 리스크 스코어링 API에서 처리하도록 되어 있습니다. 필요시 백엔드에서도 체크할 수 있도록 `load_sdn_list()` 함수를 구현할 수 있습니다.

---

## 📚 추가 참고 자료

- [리스크 스코어링 API 문서](../risk-scoring/docs/API_DOCUMENTATION.md)
- [통합 가이드](./INTEGRATION_GUIDE.md)
- [핵심 로직 설명](./CORE_LOGIC.md)

---

## 🤝 문의

통합 과정에서 문제가 발생하면 백엔드 팀이나 예림님께 문의해주세요!
