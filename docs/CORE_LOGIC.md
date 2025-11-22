# 🧠 Trace-X 핵심 로직 가이드

이 문서는 Trace-X 프로젝트의 핵심 로직과 데이터 플로우를 상세히 설명합니다.

## 📋 목차

1. [전체 시스템 아키텍처](#전체-시스템-아키텍처)
2. [데이터 플로우 (단계별)](#데이터-플로우-단계별)
3. [리스크 스코어링 핵심 로직](#리스크-스코어링-핵심-로직)
4. [룰 평가 시스템](#룰-평가-시스템)
5. [점수 계산 방법](#점수-계산-방법)
6. [데이터 구조](#데이터-구조)
7. [코드 예시](#코드-예시)

---

## 🏗️ 전체 시스템 아키텍처

Trace-X는 **3-tier 구조**로 설계되었습니다:

```
┌─────────────────────────────────────────┐
│  Frontend (포트 5173)                   │
│  - React + TypeScript                   │
│  - 사용자 인터페이스                    │
│  - 주소 입력 및 결과 시각화             │
└──────────────┬──────────────────────────┘
               │ HTTP 요청
               ↓
┌─────────────────────────────────────────┐
│  Backend (포트 8888)                    │
│  - Flask API                            │
│  - Etherscan API로 거래 데이터 수집     │
│  - 그래프 데이터 생성                   │
│  - 데이터 형식 변환                     │
└──────────────┬──────────────────────────┘
               │ HTTP 요청
               ↓
┌─────────────────────────────────────────┐
│  Risk Scoring API (포트 5001)           │
│  - Python + NetworkX                    │
│  - 룰 평가 엔진                         │
│  - 리스크 점수 계산                     │
│  - 그래프 패턴 탐지                     │
└─────────────────────────────────────────┘
```

### 컴포넌트 역할

1. **Frontend**: 사용자 인터페이스, 주소 입력, 결과 시각화
2. **Backend**: 블록체인 데이터 수집, 그래프 생성, 데이터 변환
3. **Risk Scoring API**: 룰 평가, 점수 계산, 패턴 탐지

---

## 🔄 데이터 플로우 (단계별)

### 단계 1: 프론트엔드에서 시작

사용자가 주소를 입력하고 "분석하기" 버튼을 클릭합니다.

**코드 위치**: `trace-x/frontend/src/pages/adhoc/index.tsx`

```typescript
// 사용자가 주소 입력: "0x742d35..."
// 분석하기 버튼 클릭

fundFlowData = await getFundFlow(
  address.trim(),  // "0x742d35..."
  chainId,         // 1 (Ethereum)
  1,               // max_hops: 1홉
  5                // max_addresses: 방향당 5개
)
```

**HTTP 요청**:
```
GET /api/analysis/fund-flow?address=0x742d35...&chain_id=1&max_hops=1&max_addresses=5
```

---

### 단계 2: 백엔드에서 거래 데이터 수집

백엔드는 **두 가지 주요 역할**을 수행합니다.

#### 역할 1: Etherscan API로 거래 데이터 수집

**코드 위치**: `trace-x/backend/src/api/analysis.py`

```python
def get_multihop_fund_flow_for_scoring(self, chain_id, address, max_hops=1, ...):
    """
    Multi-hop 그래프 데이터 수집
    
    Args:
        chain_id: 체인 ID (1=Ethereum, 56=BSC, 137=Polygon)
        address: 분석 대상 주소
        max_hops: 최대 홉 수 (1, 2, 3)
        max_addresses_per_direction: 방향당 최대 주소 수
    """
    # 1. Etherscan API 호출하여 거래 내역 가져오기
    normal_txs = self._fetch_normal_txs(chain_id, address)      # 일반 거래
    erc20_txs = self._fetch_erc20_transfers(chain_id, address)  # ERC20 토큰 거래
    
    # 2. 그래프 구조 생성 (nodes + edges)
    graph = ScoringGraph()
    
    # 3. 각 거래를 그래프의 edge로 추가
    for tx in normal_txs:
        from_addr = tx['from'].lower()
        to_addr = tx['to'].lower()
        
        # 노드 추가
        graph.add_node(from_addr, chain_id, ...)
        graph.add_node(to_addr, chain_id, ...)
        
        # Edge 추가 (from → to)
        graph.add_edge(
            from_address=from_addr,
            to_address=to_addr,
            tx_hash=tx['hash'],
            timestamp=tx['timeStamp'],
            usd_value=tx.get('value_usd', 0),
            tx_type='transfer',
            ...
        )
    
    return graph.to_dict()  # {nodes: [...], edges: [...]}
```

**결과 데이터 구조**:
```json
{
  "nodes": [
    {
      "address": "0x742d35...",
      "chain_id": 1,
      "label": "unknown"
    },
    {
      "address": "0xABC123...",
      "chain_id": 1,
      "label": "unknown"
    }
  ],
  "edges": [
    {
      "from_address": "0x742d35...",
      "to_address": "0xABC123...",
      "tx_hash": "0x...",
      "timestamp": 1234567890,
      "usd_value": 1000.0,
      "tx_type": "transfer"
    }
  ]
}
```

#### 역할 2: 그래프 데이터를 거래 배열로 변환

**코드 위치**: `trace-x/backend/src/api/risk_scoring.py`

```python
def convert_graph_to_transactions(graph_data: Dict[str, Any], target_address: str) -> List[Dict[str, Any]]:
    """
    백엔드의 그래프 데이터를 리스크 스코어링 API 형식으로 변환
    
    Args:
        graph_data: 백엔드 그래프 데이터 {nodes: [...], edges: [...]}
        target_address: 분석 대상 주소
    
    Returns:
        리스크 스코어링 API 형식의 거래 배열
    """
    transactions = []
    edges = graph_data.get('edges', [])
    
    for edge in edges:
        from_addr = edge.get('from_address', '').lower()
        to_addr = edge.get('to_address', '').lower()
        
        # SDN 리스트 체크 (제재 대상 주소)
        is_sanctioned = from_addr in SDN_LIST or to_addr in SDN_LIST
        
        # 상대방 주소 추출
        if from_addr == target_address.lower():
            counterparty = to_addr
        else:
            counterparty = from_addr
        
        # 거래 데이터 변환
        tx = {
            "tx_hash": edge.get('tx_hash', ''),
            "chain_id": edge.get('chain_id', 1),
            "timestamp": convert_timestamp(edge.get('timestamp', '')),  # ISO8601 형식
            "block_height": edge.get('block_height', 0),
            "from": from_addr,
            "to": to_addr,
            "target_address": target_address.lower(),
            "counterparty_address": counterparty,
            "label": infer_label(edge),  # "mixer" | "bridge" | "unknown"
            "is_sanctioned": is_sanctioned,  # ✅ SDN 리스트 체크!
            "is_known_scam": False,
            "is_mixer": False,
            "is_bridge": edge.get('tx_type', '') == 'bridge',
            "amount_usd": float(edge.get('usd_value', 0)),
            "asset_contract": edge.get('token_address', '0xETH')
        }
        
        transactions.append(tx)
    
    return transactions
```

**변환 결과**:
```json
{
  "transactions": [
    {
      "tx_hash": "0x...",
      "chain_id": 1,
      "timestamp": "2025-01-01T12:00:00Z",
      "from": "0x742d35...",
      "to": "0xABC123...",
      "target_address": "0x742d35...",
      "counterparty_address": "0xABC123...",
      "is_sanctioned": false,
      "is_bridge": false,
      "amount_usd": 1000.0,
      "label": "unknown"
    }
  ]
}
```

---

### 단계 3: 리스크 스코어링 API 호출

**코드 위치**: `trace-x/backend/src/api/risk_scoring.py`

```python
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
        transactions: 거래 배열 (위에서 변환한 데이터)
        analysis_type: "basic" 또는 "advanced"
    
    Returns:
        리스크 스코어링 결과
    """
    url = f"{RISK_SCORING_API_URL}/api/analyze/address"
    
    payload = {
        "address": address,           # "0x742d35..."
        "chain_id": chain_id,         # 1
        "transactions": transactions,  # 거래 배열
        "analysis_type": analysis_type  # "basic" 또는 "advanced"
    }
    
    response = requests.post(url, json=payload, timeout=30)
    response.raise_for_status()
    return response.json()
```

**HTTP 요청**:
```
POST http://localhost:5001/api/analyze/address
Content-Type: application/json

{
  "address": "0x742d35...",
  "chain_id": 1,
  "transactions": [...],
  "analysis_type": "basic"
}
```

---

### 단계 4: 리스크 스코어링 API에서 룰 평가

#### 4-1. 주소 분석기 실행

**코드 위치**: `trace-x/risk-scoring/core/scoring/address_analyzer.py`

```python
class AddressAnalyzer:
    """주소 기반 리스크 분석기"""
    
    def analyze_address(
        self,
        address: str,
        chain: str,
        transactions: List[Dict[str, Any]],
        analysis_type: str = "basic"
    ) -> AddressAnalysisResult:
        """
        주소의 모든 거래 히스토리를 분석하여 리스크 스코어 계산
        
        Args:
            address: 분석할 주소
            chain: 블록체인 (ethereum, bsc, polygon)
            transactions: 거래 히스토리 리스트
            analysis_type: "basic" 또는 "advanced"
        
        Returns:
            주소 분석 결과 (리스크 점수, 발동된 룰 등)
        """
        if not transactions:
            return self._empty_result(address, chain)
        
        # 1. 트랜잭션을 시간순으로 정렬
        sorted_txs = sorted(
            transactions,
            key=lambda tx: self._get_timestamp(tx)
        )
        
        # 2. 각 트랜잭션에 대해 룰 평가
        all_fired_rules = []
        transaction_scores = []
        timeline = []
        
        # 그래프 구조 분석 포함 여부 결정
        include_topology = (analysis_type == "advanced")
        
        for tx in sorted_txs:
            # 트랜잭션 데이터 변환
            tx_data = self._convert_transaction(tx, address)
            
            # 룰 평가 (핵심 로직!)
            fired_rules = self.rule_evaluator.evaluate_single_transaction(
                tx_data,
                include_topology=include_topology
            )
            
            # 트랜잭션별 점수 계산 (발동된 룰 점수 합산)
            tx_score = sum(r.get("score", 0) for r in fired_rules)
            transaction_scores.append(tx_score)
            
            # 발동된 룰 수집
            all_fired_rules.extend(fired_rules)
            
            # 타임라인 추가
            timeline.append({
                "timestamp": tx.get("timestamp"),
                "tx_hash": tx.get("tx_hash"),
                "risk_score": min(100.0, tx_score),
                "fired_rules": [r["rule_id"] for r in fired_rules]
            })
        
        # 3. 최종 리스크 스코어 계산
        final_score = self._calculate_final_score(transaction_scores, sorted_txs)
        
        # 4. Risk Level 결정
        risk_level = self._determine_risk_level(final_score)
        
        # 5. 발동된 룰 집계 (중복 제거 및 카운트)
        aggregated_rules = self._aggregate_rules(all_fired_rules)
        
        # 6. Risk Tags 생성
        risk_tags = self._generate_risk_tags(aggregated_rules)
        
        return AddressAnalysisResult(
            address=address,
            chain=chain,
            risk_score=final_score,      # 0~100 점수
            risk_level=risk_level,       # low/medium/high/critical
            fired_rules=aggregated_rules,  # 발동된 룰 목록
            risk_tags=risk_tags,         # 리스크 태그
            timeline=timeline,           # 거래별 타임라인
            explanation=explanation,     # 설명 텍스트
            completed_at=completed_at    # 완료 시각
        )
```

---

## 📜 룰 평가 시스템

### 룰 평가기 동작 원리

**코드 위치**: `trace-x/risk-scoring/core/rules/evaluator.py`

```python
class RuleEvaluator:
    """룰 평가기"""
    
    def evaluate_single_transaction(
        self,
        tx_data: Dict[str, Any],
        include_topology: bool = False
    ) -> List[Dict[str, Any]]:
        """
        단일 트랜잭션에 대한 룰 평가
        
        룰북(tracex_rules.yaml)의 모든 룰을 확인하여
        조건에 맞는 룰이 있으면 "발동(fired)"시킴
        
        Args:
            tx_data: 트랜잭션 데이터
            include_topology: 그래프 구조 분석 룰 포함 여부
        
        Returns:
            발동된 룰 목록 [{"rule_id": "...", "score": 30, ...}, ...]
        """
        fired_rules = []
        rules = self.rule_loader.get_rules()  # YAML 파일 로드
        lists = self.list_loader.get_all_lists()  # SDN 리스트 등
        
        # 트랜잭션 히스토리에 추가 (윈도우 룰 평가를 위해)
        target_address = tx_data.get("to") or tx_data.get("target_address")
        if target_address:
            self.window_evaluator.history.add_transaction(target_address, tx_data)
        
        # 각 룰에 대해 평가
        for rule in rules:
            rule_id = rule.get("id")
            
            # 1. Match 조건 확인 (기본 조건)
            if not self._check_match(tx_data, rule, lists):
                continue  # 조건 안 맞으면 스킵
            
            # 2. Conditions 확인 (추가 조건)
            if not self._check_conditions(tx_data, rule, lists):
                continue
            
            # 3. Exceptions 확인 (예외 조건)
            if self._check_exceptions(tx_data, rule, lists):
                continue  # 예외에 해당하면 스킵
            
            # 4. 룰 발동!
            score = rule.get("score", 30)
            fired_rules.append({
                "rule_id": rule_id,
                "score": float(score),
                "axis": rule.get("axis"),  # "C", "E", "B"
                "name": rule.get("name"),
                "severity": rule.get("severity")
            })
        
        return fired_rules
```

### 룰 평가 예시

#### 예시 1: C-001 룰 (Sanction Direct Touch)

**룰북 정의** (`trace-x/risk-scoring/rules/tracex_rules.yaml`):
```yaml
- id: C-001
  name: Sanction Direct Touch
  axis: C  # Compliance
  severity: HIGH
  description: Direct interaction with SDN list
  match:
    any:
    - in_list:
        field: from
        list: SDN_LIST  # SDN 리스트에 있는 주소인가?
    - in_list:
        field: to
        list: SDN_LIST
  conditions:
    all:
    - gte:
        field: usd_value
        value: 1  # 1달러 이상인가?
  exceptions:
    any:
    - tag:
        field: from
        key: CEX_INTERNAL
        equals: true
  score: 30  # 발동 시 30점 추가
```

**평가 과정**:
```
거래 데이터:
  from = "0xABC..." (SDN 리스트에 있음)
  to = "0x742d35..." (분석 대상)
  amount_usd = 1000.0

1. Match 확인:
   - from이 SDN_LIST에 있나? → ✅ YES
   
2. Conditions 확인:
   - usd_value >= 1? → ✅ YES (1000 >= 1)
   
3. Exceptions 확인:
   - from이 CEX_INTERNAL 태그? → ❌ NO
   
4. 룰 발동!
   → fired_rules에 추가: {"rule_id": "C-001", "score": 30}
```

#### 예시 2: B-101 룰 (Burst - 10분 내 급증)

**룰북 정의**:
```yaml
- id: B-101
  name: Burst (10m)
  axis: B  # Behavior
  severity: MEDIUM
  window:
    duration_sec: 600  # 10분 윈도우
  aggregations:
  - count_gte:
      field: tx_hash
      value: 3  # 10분 내 3개 이상 거래?
  score: 20
```

**평가 과정**:
```
거래 히스토리:
  - 10:00 → tx1
  - 10:05 → tx2  
  - 10:08 → tx3  ← 현재 거래

1. 윈도우 확인:
   - 현재 시각: 10:08
   - 윈도우: 9:58 ~ 10:08 (10분)
   
2. 집계:
   - 윈도우 내 거래 수: 3개
   
3. 조건 확인:
   - count >= 3? → ✅ YES (3 >= 3)
   
4. 룰 발동!
   → fired_rules에 추가: {"rule_id": "B-101", "score": 20}
```

#### 예시 3: E-101 룰 (Mixer Direct Exposure)

**룰북 정의**:
```yaml
- id: E-101
  name: Mixer Direct Exposure
  axis: E  # Exposure
  severity: HIGH
  match:
    any:
    - equals:
        field: label
        value: mixer  # 믹서와 직접 거래?
  conditions:
    all:
    - gte:
        field: usd_value
        value: 0.1
  score: 25
```

**평가 과정**:
```
거래 데이터:
  from = "0x742d35..."
  to = "0xDEF..." (Tornado Cash 믹서)
  label = "mixer"
  amount_usd = 5.0

1. Match 확인:
   - label == "mixer"? → ✅ YES
   
2. Conditions 확인:
   - usd_value >= 0.1? → ✅ YES (5.0 >= 0.1)
   
3. 룰 발동!
   → fired_rules에 추가: {"rule_id": "E-101", "score": 25}
```

---

## 🎯 점수 계산 방법

### 최종 점수 계산

**코드 위치**: `trace-x/risk-scoring/core/scoring/address_analyzer.py`

```python
def _calculate_final_score(
    self,
    transaction_scores: List[float],
    transactions: List[Dict[str, Any]]
) -> float:
    """
    최종 리스크 스코어 계산
    
    방법: 최대 점수와 가중 평균 중 더 높은 값 사용
    최대 100점으로 제한
    
    Args:
        transaction_scores: 각 거래별 점수 리스트
        transactions: 거래 리스트
    
    Returns:
        0~100 사이의 최종 리스크 스코어
    """
    if not transaction_scores:
        return 0.0
    
    # 1. 최대 점수
    max_score = max(transaction_scores)  # 예: 30
    
    # 2. 가중 평균 (최근 거래가 더 중요)
    if len(transactions) > 1:
        recent_weight = 0.7  # 최근 거래 가중치
        old_weight = 0.3     # 과거 거래 가중치
        
        recent_count = max(1, int(len(transaction_scores) * 0.3))
        recent_scores = transaction_scores[-recent_count:]
        old_scores = transaction_scores[:-recent_count]
        
        recent_avg = sum(recent_scores) / len(recent_scores) if recent_scores else 0
        old_avg = sum(old_scores) / len(old_scores) if old_scores else 0
        
        weighted_avg = (recent_weight * recent_avg) + (old_weight * old_avg)
    else:
        weighted_avg = transaction_scores[0]
    
    # 3. 더 높은 값 사용 (최대 100점)
    final_score = min(100.0, max(max_score, weighted_avg))
    
    return final_score
```

### Risk Level 결정

```python
def _determine_risk_level(self, score: float) -> str:
    """
    점수를 리스크 레벨로 변환
    
    Args:
        score: 0~100 사이의 리스크 스코어
    
    Returns:
        "low" | "medium" | "high" | "critical"
    """
    if score >= 75:
        return "critical"
    elif score >= 50:
        return "high"
    elif score >= 25:
        return "medium"
    else:
        return "low"
```

**점수 범위**:
- **0~24**: Low (낮음)
- **25~49**: Medium (보통)
- **50~74**: High (높음)
- **75~100**: Critical (매우 높음)

---

## 📊 데이터 구조

### 전체 데이터 플로우 요약

```
1. 프론트엔드
   ↓ 주소 입력: "0x742d35..."
   
2. 백엔드
   ↓ Etherscan API 호출
   ↓ 그래프 데이터 생성:
   {
     nodes: [
       {address: "0x742d35...", chain_id: 1},
       {address: "0xABC...", chain_id: 1}
     ],
     edges: [
       {
         from_address: "0x742d35...",
         to_address: "0xABC...",
         tx_hash: "0x...",
         usd_value: 1000.0,
         timestamp: 1234567890
       }
     ]
   }
   ↓ 거래 배열 변환:
   [
     {
       tx_hash: "0x...",
       from: "0x742d35...",
       to: "0xABC...",
       target_address: "0x742d35...",
       is_sanctioned: false,
       amount_usd: 1000.0,
       ...
     }
   ]
   ↓ 리스크 스코어링 API 호출
   
3. 리스크 스코어링 API
   ↓ 룰 평가 (각 거래마다)
   ↓ 점수 계산
   ↓ 결과 반환:
   {
     target_address: "0x742d35...",
     risk_score: 85,
     risk_level: "high",
     fired_rules: [
       {rule_id: "C-001", score: 30},
       {rule_id: "E-101", score: 25},
       {rule_id: "B-101", score: 20}
     ],
     risk_tags: ["sanctioned", "mixer_inflow"],
     explanation: "...",
     completed_at: "2025-01-01T12:00:00Z"
   }
   ↓ 백엔드 → 프론트엔드 → 사용자
```

---

## 🎨 룰 축 (Axis) 분류

### C (Compliance) - 규정 준수

제재 대상 주소와의 직접 거래, 고액 거래 등 규정 위반 탐지

**대표 룰**:
- **C-001**: Sanction Direct Touch (제재 대상과 직접 거래)
- **C-003**: High-Value Single Transfer (고액 단일 거래)
- **C-004**: High-Value Repeated Transfer (고액 반복 거래)

### E (Exposure) - 노출

위험 주소와의 접촉 정도 평가

**대표 룰**:
- **E-101**: Mixer Direct Exposure (믹서와 직접 거래)
- **E-102**: Indirect Sanctions Exposure (PPR 기반 간접 제재 노출)

### B (Behavior) - 행동 패턴

이상 행동 패턴 탐지

**대표 룰**:
- **B-101**: Burst (10분 내 급증)
- **B-102**: Rapid Sequence (1분 내 연속 거래)
- **B-201**: Layering Chain (레이어링 체인)
- **B-202**: Cycle (순환 구조)

---

## 🔍 핵심 포인트 정리

### 1. 리스크 스코어링은 주소 하나만 받는 게 아님 ❌

**입력**:
- `address`: 분석 대상 주소 (1개) ✅
- `transactions`: 해당 주소의 **모든 거래 배열** (여러 개) ✅

### 2. 룰 평가는 각 거래마다 수행

```
거래1 → 룰 평가 → [C-001 발동: 30점]
거래2 → 룰 평가 → [B-101 발동: 20점]
거래3 → 룰 평가 → [발동 없음: 0점]
...
```

### 3. 최종 점수는 모든 거래의 점수를 집계

- **방법**: 최대 점수와 가중 평균 중 더 높은 값 사용
- **범위**: 0~100점

### 4. 룰은 3개 축으로 분류

- **C (Compliance)**: 규정 위반 탐지
- **E (Exposure)**: 위험 주소 노출
- **B (Behavior)**: 이상 행동 패턴

---

## 📁 주요 파일 위치

### 프론트엔드
- `trace-x/frontend/src/pages/adhoc/index.tsx` - Ad-hoc 분석 페이지
- `trace-x/frontend/src/services/backend.ts` - 백엔드 API 호출

### 백엔드
- `trace-x/backend/src/app.py` - Flask API 엔드포인트
- `trace-x/backend/src/api/analysis.py` - 거래 데이터 수집
- `trace-x/backend/src/api/risk_scoring.py` - 리스크 스코어링 연동

### 리스크 스코어링
- `trace-x/risk-scoring/core/scoring/address_analyzer.py` - 주소 분석기
- `trace-x/risk-scoring/core/rules/evaluator.py` - 룰 평가기
- `trace-x/risk-scoring/rules/tracex_rules.yaml` - 룰북 정의

---

## 🔗 관련 문서

- [API 문서](API_DOCUMENTATION.md)
- [통합 가이드](INTEGRATION_GUIDE.md)
- [시스템 개요](../risk-scoring/docs/SYSTEM_OVERVIEW.md)
- [룰 구현 현황](../risk-scoring/docs/IMPLEMENTED_RULES_SUMMARY.md)

---

**마지막 업데이트**: 2025-01-22

