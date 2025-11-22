# 🏗️ Trace-X 시스템 아키텍처

Trace-X의 전체 시스템 아키텍처와 설계 원칙을 설명합니다.

---

## 📋 목차

1. [시스템 개요](#시스템-개요)
2. [아키텍처 다이어그램](#아키텍처-다이어그램)
3. [컴포넌트 상세](#컴포넌트-상세)
4. [데이터 플로우](#데이터-플로우)
5. [기술 스택](#기술-스택)
6. [설계 원칙](#설계-원칙)
7. [확장성 고려사항](#확장성-고려사항)

---

## 🎯 시스템 개요

Trace-X는 **블록체인 주소의 위험도를 분석하는 3-tier 아키텍처**입니다.

### 핵심 기능

- 🔍 **Multi-hop 거래 추적**: 1-hop부터 3-hop까지 재귀적 거래 분석
- 🎯 **리스크 스코어링**: 50+ 룰 기반 위험도 평가 (0-100점)
- 📊 **그래프 패턴 탐지**: Layering Chain, Cycle, Fan-in/out 등 세탁 패턴 탐지
- 🌐 **Multi-chain 지원**: Ethereum, BSC, Polygon
- 🚀 **실시간 분석**: 주소 입력 즉시 위험도 분석

### 시스템 목표

1. **정확성**: 신뢰할 수 있는 위험도 평가
2. **성능**: 빠른 응답 시간 (1-hop: ~5초, 3-hop: ~15-30초)
3. **확장성**: 새로운 체인 및 룰 추가 용이
4. **유지보수성**: 명확한 컴포넌트 분리

---

## 🏛️ 아키텍처 다이어그램

### 전체 시스템 구조

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend Layer                        │
│                  (React + TypeScript)                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ Dashboard  │  │   Live     │  │   Adhoc    │       │
│  │   Page     │  │ Detection  │  │  Analysis  │       │
│  └────────────┘  └────────────┘  └────────────┘       │
│                        │                                │
│                  HTTP/REST API                          │
└────────────────────────┼────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────┐
│                    Backend Layer                         │
│                    (Flask API)                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  API Endpoints                                    │  │
│  │  - /api/analysis/risk-scoring                     │  │
│  │  - /api/analysis/fund-flow                        │  │
│  │  - /api/dashboard/*                               │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Analysis Engine                                  │  │
│  │  - EtherscanV2Client                             │  │
│  │  - Multi-hop graph builder                       │  │
│  │  - Graph to transaction converter                │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                                │
│              External API + Internal API                │
└────────────────────────┼────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Etherscan    │  │   Risk       │  │   Other      │
│   API        │  │  Scoring     │  │   Services   │
│              │  │    API       │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────┐
│              Risk Scoring Layer                         │
│              (Python + NetworkX)                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Rule Evaluator                                   │  │
│  │  - Compliance Rules (C-*)                        │  │
│  │  - Exposure Rules (E-*)                          │  │
│  │  - Behavior Rules (B-*)                          │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Aggregation Engine                               │  │
│  │  - Graph pattern detection                       │  │
│  │  - Statistical aggregation                       │  │
│  │  - Score calculation                             │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 컴포넌트 상세

### 1. Frontend (`frontend/`)

**역할**: 사용자 인터페이스 및 상호작용

**기술 스택**:

- React 19
- TypeScript
- Vite
- ReactFlow (그래프 시각화)
- Styled Components

**주요 페이지**:

- **Dashboard**: 전체 통계 및 요약
- **Live Detection**: 실시간 거래 모니터링
- **Adhoc Analysis**: 주소 수동 분석 ⭐ (핵심 기능)

**데이터 흐름**:

```
User Input (주소, 체인)
  ↓
API Service (src/api/*.ts)
  ↓
Backend API Call
  ↓
Response Processing
  ↓
UI Rendering (그래프, 점수, 룰 목록)
```

**주요 파일**:

- `src/pages/adhoc/index.tsx` - Adhoc 분석 페이지
- `src/api/getFundFlow.ts` - Fund flow API 호출
- `src/api/getRiskScoring.ts` - 리스크 스코어링 API 호출

---

### 2. Backend (`backend/`)

**역할**: 데이터 수집, 변환, API 게이트웨이

**기술 스택**:

- Flask
- Python 3.10+
- Etherscan API
- NetworkX (그래프 처리)

**주요 모듈**:

#### 2.1. API Layer (`src/api/`)

- **`analysis.py`**: 거래 분석 엔드포인트

  - `get_multihop_fund_flow_for_scoring()`: Multi-hop 그래프 데이터 수집
  - `get_transaction_fund_flow()`: 트랜잭션 기반 자금 흐름 분석

- **`risk_scoring.py`**: 리스크 스코어링 연동 ⭐

  - `convert_graph_to_transactions()`: 그래프 데이터 → 거래 배열 변환
  - `call_risk_scoring_api()`: 리스크 스코어링 API 호출
  - `analyze_address_with_risk_scoring()`: 전체 플로우 통합

- **`etherscan_v2.py`**: Etherscan API 클라이언트
  - `EtherscanV2Client`: Etherscan API V2 래퍼
  - `get_transactions()`: 거래 내역 조회
  - `get_token_transfers()`: 토큰 전송 조회

#### 2.2. Graph Builder

- **`src/api/analysis.py`**: 그래프 생성 로직
  - `Graph`: 노드/엣지 데이터 구조
  - `Node`: 주소 정보
  - `Edge`: 거래 정보

**데이터 변환 파이프라인**:

```
Etherscan API Response
  ↓
Raw Transaction Data
  ↓
Graph Construction (Nodes + Edges)
  ↓
Transaction Array (리스크 스코어링 API 형식)
  ↓
Risk Scoring API Call
```

---

### 3. Risk Scoring API (`risk-scoring/`)

**역할**: 거래 분석 및 리스크 평가

**기술 스택**:

- Flask
- Python 3.10+
- NetworkX (그래프 분석)
- YAML (룰 정의)

**주요 모듈**:

#### 3.1. Rule Engine (`core/rules/`)

- **`evaluator.py`**: 룰 평가 엔진

  - TRACE-X 룰북 기반 룰 평가
  - Compliance, Exposure, Behavior 룰 분류

- **`loader.py`**: 룰북 로더
  - YAML 룰 정의 파싱
  - 룰 조건 검증

**룰 구조**:

```yaml
rules:
  C-001:
    name: "Sanctioned Address Exposure"
    category: "compliance"
    conditions:
      - field: "is_sanctioned"
        operator: "=="
        value: true
    score: 30
```

#### 3.2. Aggregation Engine (`core/aggregation/`)

- **`topology.py`**: 그래프 구조 분석

  - Layering Chain 탐지
  - Cycle 탐지
  - Fan-in/Fan-out 분석

- **`stats.py`**: 통계 집계

  - 거래 금액 통계
  - 시간 윈도우 분석
  - 빈도 분석

- **`mpocryptml_patterns.py`**: MPOCryptoML 패턴 탐지
  - 논문 기반 세탁 패턴 탐지

**점수 계산 프로세스**:

```
1. 각 거래마다 룰 평가
2. 발동된 룰의 점수 합산
3. 그래프 패턴 분석 (advanced 모드)
4. 최종 점수 계산 (0-100)
5. 리스크 레벨 분류 (low/medium/high/critical)
```

---

## 🔄 데이터 플로우

### 전체 데이터 플로우

```
1. 사용자 입력
   └─> 주소: "0x742d35..."
   └─> 체인: Ethereum (chain_id: 1)
   └─> Hop 수: 3
   └─> 분석 타입: "basic" 또는 "advanced"

2. Frontend → Backend
   └─> POST /api/analysis/risk-scoring
   └─> {
         "address": "0x742d35...",
         "chain_id": 1,
         "max_hops": 3,
         "analysis_type": "basic"
       }

3. Backend: 데이터 수집
   └─> Etherscan API 호출 (재귀적)
   └─> 1-hop: 직접 거래
   └─> 2-hop: 1단계 상대방과의 거래
   └─> 3-hop: 2단계 상대방과의 거래
   └─> 그래프 데이터 생성: {nodes: [...], edges: [...]}

4. Backend: 데이터 변환
   └─> convert_graph_to_transactions()
   └─> edges → transactions 배열 변환
   └─> [{tx_hash, from, to, amount_usd, ...}, ...]

5. Backend → Risk Scoring API
   └─> POST http://localhost:5001/api/analyze/address
   └─> {
         "address": "0x742d35...",
         "chain_id": 1,
         "transactions": [...],
         "analysis_type": "basic"
       }

6. Risk Scoring API: 분석
   └─> 각 거래마다 룰 평가
   └─> Compliance Rules (C-*)
   └─> Exposure Rules (E-*)
   └─> Behavior Rules (B-*)
   └─> 그래프 패턴 탐지 (advanced 모드)
   └─> 점수 계산 및 집계

7. Risk Scoring API → Backend
   └─> {
         "final_score": 85,
         "risk_level": "high",
         "fired_rules": [...],
         "risk_tags": ["sanctioned", "mixer"],
         "explanation": "..."
       }

8. Backend → Frontend
   └─> Response 반환
   └─> UI 업데이트 (그래프, 점수, 룰 목록)
```

### 상세 플로우: Multi-hop 데이터 수집

```
시작 주소: 0xABC...
max_hops: 3

Hop 0 (시작):
  └─> 0xABC...

Hop 1 (1-hop):
  └─> 0xABC... → 0xDEF... (거래 1)
  └─> 0xABC... → 0xGHI... (거래 2)
  └─> 0xJKL... → 0xABC... (거래 3)

Hop 2 (2-hop):
  └─> 0xDEF... → 0xMNO... (거래 4)
  └─> 0xGHI... → 0xPQR... (거래 5)
  └─> 0xSTU... → 0xDEF... (거래 6)

Hop 3 (3-hop):
  └─> 0xMNO... → 0xVWX... (거래 7)
  └─> ...

최종 그래프:
  Nodes: [0xABC..., 0xDEF..., 0xGHI..., ...]
  Edges: [거래 1, 거래 2, 거래 3, ...]
```

---

## 🛠️ 기술 스택

### Frontend

| 기술              | 버전    | 용도            |
| ----------------- | ------- | --------------- |
| React             | 19.1.1  | UI 프레임워크   |
| TypeScript        | 5.8.3   | 타입 안정성     |
| Vite              | 7.1.2   | 빌드 도구       |
| ReactFlow         | 11.11.4 | 그래프 시각화   |
| Styled Components | 6.19    | 스타일링        |
| Axios             | 1.13.2  | HTTP 클라이언트 |

### Backend

| 기술          | 버전    | 용도            |
| ------------- | ------- | --------------- |
| Flask         | 2.3.0+  | 웹 프레임워크   |
| Python        | 3.10+   | 프로그래밍 언어 |
| Etherscan API | V2      | 블록체인 데이터 |
| NetworkX      | -       | 그래프 처리     |
| Requests      | 2.28.0+ | HTTP 클라이언트 |

### Risk Scoring

| 기술     | 버전  | 용도            |
| -------- | ----- | --------------- |
| Flask    | -     | 웹 프레임워크   |
| Python   | 3.10+ | 프로그래밍 언어 |
| NetworkX | -     | 그래프 분석     |
| PyYAML   | -     | 룰 정의 파싱    |

### Infrastructure

| 기술           | 용도           |
| -------------- | -------------- |
| Docker         | 컨테이너화     |
| Docker Compose | 오케스트레이션 |
| Git            | 버전 관리      |
| GitHub         | 코드 저장소    |

---

## 🎨 설계 원칙

### 1. 관심사 분리 (Separation of Concerns)

각 레이어는 명확한 역할을 가집니다:

- **Frontend**: UI/UX 담당
- **Backend**: 데이터 수집 및 변환 담당
- **Risk Scoring**: 분석 로직 담당

### 2. 느슨한 결합 (Loose Coupling)

컴포넌트 간 HTTP API로 통신하여 독립적 배포 및 확장 가능

### 3. 단일 책임 원칙 (Single Responsibility)

각 모듈은 하나의 책임만 가집니다:

- `analysis.py`: 거래 분석만 담당
- `risk_scoring.py`: 리스크 스코어링 연동만 담당
- `etherscan_v2.py`: Etherscan API 호출만 담당

### 4. 확장 가능성 (Extensibility)

- 새로운 체인 추가: `chain_id_mapping.py`에 추가
- 새로운 룰 추가: `tracex_rules.yaml`에 추가
- 새로운 분석 타입 추가: `analysis_type` 파라미터로 확장

### 5. 성능 최적화

- **1-hop 기본 분석**: 빠른 응답 (~5초)
- **3-hop 심층 분석**: 정밀 분석 (~15-30초)
- **캐싱**: 동일 주소 재분석 시 캐싱 활용 가능
- **비동기 처리**: 프론트엔드에서 비동기 API 호출

---

## 📈 확장성 고려사항

### 수평 확장 (Horizontal Scaling)

1. **Backend**: 여러 인스턴스 실행 가능 (로드 밸런서 사용)
2. **Risk Scoring API**: 여러 인스턴스 실행 가능
3. **Frontend**: 정적 파일이므로 CDN 배포 가능

### 수직 확장 (Vertical Scaling)

1. **성능 튜닝**:

   - Etherscan API 호출 최적화
   - 그래프 처리 최적화
   - 데이터베이스 캐싱 (추후 추가)

2. **리소스 최적화**:
   - 메모리 사용량 최적화
   - CPU 사용량 최적화
   - 네트워크 대역폭 최적화

### 미래 확장 계획

1. **데이터베이스 추가**: 분석 결과 저장 및 캐싱
2. **메시지 큐 추가**: 비동기 작업 처리 (RabbitMQ/Kafka)
3. **모니터링 추가**: Prometheus + Grafana
4. **로그 시스템**: ELK Stack 또는 CloudWatch

---

## 📚 관련 문서

- [API 문서](API.md) - API 사용 방법 상세 가이드
- [핵심 로직 가이드](CORE_LOGIC.md) - 데이터 플로우 및 로직 상세 설명
- [통합 가이드](INTEGRATION_GUIDE.md) - 통합 설정 및 실행 가이드

---

**Made with ❤️ by the Trace-X Team**
