# Trace-X 프로젝트 개발 보고서

## 1. 프로젝트 개요

### 1.1 프로젝트 명칭

**Trace-X: Blockchain Risk Analysis Platform**

### 1.2 프로젝트 목적

블록체인 주소의 거래 히스토리를 분석하여 AML(Anti-Money Laundering) 규칙 기반으로 위험도를 평가하는 통합 플랫폼 구축

### 1.3 핵심 가치

- **정확성**: 50개 이상의 룰 기반 위험도 평가
- **신속성**: 1-hop 기본 분석은 약 5초 내 결과 제공
- **심층 분석**: 3-hop 심층 분석으로 복잡한 세탁 패턴 탐지
- **다중 체인 지원**: Ethereum, BSC, Polygon 등 여러 체인 지원
- **실시간 분석**: 주소 입력 즉시 위험도 분석 결과 제공

---

## 2. 시스템 아키텍처

### 2.1 전체 구조

Trace-X는 **3-tier 아키텍처**로 구성되어 있습니다:

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

### 2.2 컴포넌트 상세

#### 2.2.1 Frontend (포트 5173)

- **기술 스택**: React 19, TypeScript, Vite
- **역할**: 사용자 인터페이스 제공
- **주요 기능**:
  - 주소 입력 및 체인 선택
  - 분석 결과 시각화 (그래프, 점수, 룰 목록)
  - Dashboard, Live Detection, Adhoc Analysis 페이지
- **디자인**: SoCar UI/UX 기반

#### 2.2.2 Backend (포트 8888)

- **기술 스택**: Flask, Python 3.10+
- **역할**: 데이터 수집, 그래프 생성, API 게이트웨이
- **주요 기능**:
  - Etherscan API를 통한 거래 데이터 수집
  - Multi-hop 그래프 데이터 생성
  - 리스크 스코어링 API 호출 및 결과 전달
- **외부 API 연동**:
  - Etherscan API (거래 데이터 수집)
  - Dune API (대시보드 모니터링)

#### 2.2.3 Risk Scoring API (포트 5001)

- **기술 스택**: Flask, Python 3.10+, NetworkX, scikit-learn
- **역할**: 거래 분석 및 위험도 평가
- **주요 기능**:
  - TRACE-X 룰북 기반 룰 평가 (50+ 룰)
  - 그래프 패턴 탐지 (advanced 모드)
  - 리스크 점수 계산 및 집계
  - 2단계 하이브리드 스코어링 (룰 기반 90% + ML 10%)

---

## 3. 주요 구현 내용

### 3.1 Multi-hop 거래 분석

주소의 거래 관계를 재귀적으로 추적합니다:

- **1-hop**: 직접 거래 상대방 분석
- **2-hop**: 1단계 상대방과의 거래 분석
- **3-hop**: 2단계 상대방과의 거래 분석

### 3.2 리스크 스코어링 시스템

TRACE-X 룰북 기반으로 위험도를 0-100점 사이의 점수로 평가합니다:

#### 3.2.1 룰 카테고리

- **Compliance (C)**: 규정 준수 관련 룰 (제재 리스트 등)
- **Exposure (E)**: 노출 관련 룰 (간접 제재 노출 등)
- **Behavior (B)**: 행동 패턴 관련 룰 (그래프 패턴 등)

#### 3.2.2 활성 룰 현황

- **Basic 모드**: 31개 룰 활성 (1-hop 분석, 빠른 응답)
- **Advanced 모드**: 33개 룰 활성 (3-hop 분석, 그래프 패턴 탐지 포함)

#### 3.2.3 주요 발동 룰 예시

- `C-001`: Sanction Direct Touch (제재 주소 직접 거래)
- `C-003`: High-Value Transfer (고액 거래)
- `E-101`: Mixer Inflow (믹서 유입)
- `E-102`: Sanctioned Mixer Exposure (제재된 믹서 노출)
- `B-103`: Scam/Phishing Exposure (스캠/피싱 노출)
- `B-201`: Layering Chain Detection (레이어링 체인 탐지)
- `B-202`: Cycle Detection (순환 구조 탐지)

### 3.3 그래프 패턴 탐지

세탁에 자주 사용되는 패턴을 탐지합니다:

- **Layering Chain**: 다층 구조의 자금 이동
- **Cycle**: 순환 구조의 거래
- **Fan-in/Fan-out**: 다수의 주소로부터 집중되거나 분산되는 패턴

### 3.4 2단계 하이브리드 스코어링

1. **1단계**: Rule-Based + 그래프 통계 기반 스코어링
   - Rule-based 점수 (90%)
   - 그래프 통계 점수 (10%)
2. **2단계**: ML 기반 랭킹 및 최종 스코어 조정
   - Gradient Boosting 모델 사용
   - 룰 점수 집계 결과를 기반으로 최종 스코어 조정

---

## 4. 배포 현황

### 4.1 배포 환경

- **서버**: AWS EC2 (인스턴스명: `paran_TRace_X`)
- **Public IP**: `3.38.112.25`
- **컨테이너화**: Docker Compose 사용
- **네트워크**: Docker Bridge 네트워크 (`trace-x-network`)

### 4.2 서비스 배포 현황

#### 4.2.1 Risk Scoring API

- **포트**: 5001
- **외부 접근 URL**: `http://3.38.112.25:5001`
- **Health Check**: `http://3.38.112.25:5001/health`
- **Swagger UI**: `http://3.38.112.25:5001/api-docs`
- **상태**: 정상 운영 중

#### 4.2.2 Backend API

- **포트**: 8888
- **외부 접근 URL**: `http://3.38.112.25:8888`
- **Health Check**: `http://3.38.112.25:8888/health`
- **상태**: 정상 운영 중

#### 4.2.3 Frontend

- **포트**: 5173 (80으로 매핑)
- **외부 접근 URL**: `http://3.38.112.25:5173`
- **상태**: 정상 운영 중

### 4.3 환경 변수 설정

- `ETHERSCAN_API_KEY`: Etherscan API 키
- `RISK_SCORING_API_URL`: 리스크 스코어링 API URL (기본값: `http://3.38.112.25:5001`)
- `VITE_BACKEND_API_URL`: 백엔드 API URL

### 4.4 보안 그룹 설정

- **포트 5001**: Risk Scoring API 외부 접근용 (열림)
- **포트 8888**: Backend API 외부 접근용 (열림)
- **포트 5173**: Frontend 외부 접근용 (열림)

---

## 5. API 스펙 및 사용법

### 5.1 Risk Scoring API

#### 5.1.1 주소 분석 API (Manual Analysis)

**엔드포인트**: `POST /api/analyze/address`

**요청 형식**:

```json
{
  "address": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
  "chain_id": 1,
  "transactions": [
    {
      "tx_hash": "0x123...",
      "chain_id": 1,
      "timestamp": "2024-01-15T10:30:00Z",
      "block_height": 19000000,
      "target_address": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
      "counterparty_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
      "label": "cex",
      "is_sanctioned": false,
      "is_known_scam": false,
      "is_mixer": false,
      "is_bridge": false,
      "amount_usd": 1000.0,
      "asset_contract": "0xETH"
    }
  ],
  "analysis_type": "basic"
}
```

**응답 형식**:

```json
{
  "target_address": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
  "risk_score": 31,
  "risk_level": "medium",
  "risk_tags": ["high_value_transfer"],
  "fired_rules": [
    {
      "rule_id": "B-501",
      "score": 6
    },
    {
      "rule_id": "C-003",
      "score": 25
    }
  ],
  "explanation": "High-Value Single Transfer 패턴 감지로 인해 medium 리스크로 분류됨.",
  "completed_at": "2025-11-23T09:52:49.027987Z",
  "timestamp": "2024-01-17T09:15:00Z",
  "chain_id": 1,
  "value": 6100.0
}
```

#### 5.1.2 Health Check API

**엔드포인트**: `GET /health`

**응답 형식**:

```json
{
  "status": "ok",
  "service": "aml-risk-engine"
}
```

### 5.2 Backend API

#### 5.2.1 리스크 스코어링 분석

**엔드포인트**: `POST /api/analysis/risk-scoring`

**요청 형식**:

```json
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "chain_id": 1,
  "max_hops": 3,
  "analysis_type": "basic"
}
```

**응답 형식**:

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

### 5.3 백엔드에서 Risk Scoring API 호출

백엔드는 환경 변수 `RISK_SCORING_API_URL`을 통해 리스크 스코어링 API를 호출합니다:

- **Docker 환경**: `http://risk-scoring:5001` (Docker 내부 네트워크)
- **EC2 외부 접근**: `http://3.38.112.25:5001` (기본값)

---

## 6. 테스트 결과

### 6.1 통합 테스트

- **Risk Scoring API Health Check**: ✅ 정상
- **Backend Health Check**: ✅ 정상
- **Frontend 접근**: ✅ 정상

### 6.2 API 기능 테스트

- **주소 분석 API**: ✅ 정상 동작
- **리스크 스코어링**: ✅ 정상 동작
- **그래프 패턴 탐지**: ✅ 정상 동작 (Advanced 모드)

### 6.3 테스트 케이스 예시

**테스트 주소**: Vitalik Buterin (`0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`)

- **리스크 스코어**: 31점 (Medium)
- **발동된 룰**: B-501 (6점), C-003 (25점)
- **리스크 태그**: `high_value_transfer`

### 6.4 성능 테스트

- **1-hop 기본 분석**: 약 5초
- **3-hop 심층 분석**: 약 15-30초
- **API 응답 시간**: 평균 2-5초 (기본 모드)

---

## 7. 주요 해결 이슈

### 7.1 배포 이슈

1. **문제**: 서브모듈 클론 실패

   - **해결**: `setup-subdirectories.sh` 스크립트로 개별 레포 클론

2. **문제**: Python 버전 호환성 (NetworkX 3.3+)

   - **해결**: Python 3.9 → 3.10으로 업그레이드

3. **문제**: scikit-learn 모듈 누락

   - **해결**: `requirements.txt`에 `scikit-learn>=1.3.0` 추가

4. **문제**: Docker 컨테이너 Health Check 실패
   - **해결**: Health Check 엔드포인트 추가 및 `start_period` 조정

### 7.2 통합 이슈

1. **문제**: 백엔드-리스크 스코어링 API 통신

   - **해결**: 환경 변수 기반 URL 설정 및 Docker 네트워크 구성

2. **문제**: EC2 외부 접근 설정

   - **해결**: 보안 그룹 포트 열기 및 Public IP 기본값 설정

3. **문제**: TypeScript 타입 에러 (Frontend)
   - **해결**: `GraphData | null` 타입 허용 및 조건부 렌더링

### 7.3 문서화

- 문서 정리 및 `docs/archive/` 폴더로 이전
- 핵심 문서만 `docs/` 폴더에 유지
- 이모티콘 제거 (보고서 형식에 맞게)

---

## 8. 문서 구조

### 8.1 핵심 문서

- `README.md`: 프로젝트 개요 및 빠른 시작 가이드
- `docs/ARCHITECTURE.md`: 시스템 아키텍처 상세 설명
- `docs/API.md`: API 사용 가이드
- `docs/INTEGRATION_GUIDE.md`: 통합 가이드
- `docs/DEPLOYMENT.md`: 배포 가이드

### 8.2 백엔드 팀 전달 문서

- `BACKEND_TEAM_HANDOFF.md`: 리스크 스코어링 API 사용 가이드
- `backend/RISK_SCORING_API_CALL_GUIDE.md`: API 호출 상세 가이드
- `backend/SWAGGER_UI_TROUBLESHOOTING.md`: Swagger UI 문제 해결

### 8.3 리스크 스코어링 문서

- `risk-scoring/docs/RULEBOOK_DETAILED.md`: 상세 룰북
- `risk-scoring/docs/ACTIVE_RULES.md`: 활성 룰 목록
- `risk-scoring/docs/PERFORMANCE_EVALUATION.md`: 성능 평가 결과

### 8.4 배포 관련 문서

- `QUICK_DEPLOY.md`: 빠른 배포 가이드
- `DEPLOY_TO_EC2.md`: EC2 배포 상세 가이드
- `TROUBLESHOOTING.md`: 문제 해결 가이드
- `EC2_SECURITY_GROUP_PORT_5001.md`: 보안 그룹 설정 가이드

---

## 9. 향후 계획

### 9.1 단기 계획

- [ ] 캐싱 시스템 구현 (동일 주소 재분석 시 응답 시간 단축)
- [ ] Rate Limiting 구현 (API 과부하 방지)
- [ ] 로깅 시스템 고도화 (분석, 에러 추적)

### 9.2 중기 계획

- [ ] 추가 체인 지원 확대 (Arbitrum, Avalanche, Base 등)
- [ ] 실시간 모니터링 대시보드 개선
- [ ] ML 모델 성능 개선 (더 많은 학습 데이터 활용)

### 9.3 장기 계획

- [ ] 분산 시스템으로 확장 (수평 확장)
- [ ] 실시간 거래 모니터링 기능 추가
- [ ] 규제 기관 리포트 자동 생성 기능

---

## 10. 기술 스택 요약

### 10.1 Frontend

- React 19
- TypeScript
- Vite
- React Router
- Recharts (차트 시각화)

### 10.2 Backend

- Flask (Python 3.10+)
- Requests (HTTP 클라이언트)
- Etherscan API 클라이언트

### 10.3 Risk Scoring API

- Flask (Python 3.10+)
- NetworkX (그래프 분석)
- scikit-learn (머신러닝)
- PyYAML (룰 정의 파싱)

### 10.4 인프라

- Docker & Docker Compose
- AWS EC2
- Linux (Ubuntu)

---

## 11. 레포지토리 구조

### 11.1 통합 레포 (Monorepo)

- **GitHub**: `https://github.com/paran-needless-to-say/integration`
- **설명**: 모든 컴포넌트, 통합 스크립트, 문서를 포함한 통합 레포

### 11.2 개별 레포

- **Backend**: `https://github.com/paran-needless-to-say/100end`
- **Frontend**: `https://github.com/paran-needless-to-say/frontend`
- **Risk Scoring API**: `https://github.com/paran-needless-to-say/aml-risk-engine2`

---

## 12. 결론

Trace-X 프로젝트는 블록체인 주소의 위험도를 실시간으로 분석하는 통합 플랫폼으로, 다음과 같은 성과를 달성했습니다:

1. **완전한 통합 시스템 구축**: Frontend, Backend, Risk Scoring API를 통합하여 원스톱 분석 플랫폼 구축
2. **EC2 프로덕션 배포 완료**: 안정적인 운영 환경 구축
3. **50+ 룰 기반 스코어링**: 다양한 위험 패턴 탐지 가능
4. **Multi-hop 분석**: 심층적인 거래 추적 가능
5. **체계적인 문서화**: 개발 및 운영 가이드 완비

현재 시스템은 안정적으로 운영 중이며, 향후 지속적인 개선과 확장을 통해 더욱 강력한 AML 탐지 시스템으로 발전할 예정입니다.

---

**보고서 작성일**: 2025년 11월 23일  
**작성자**: Trace-X 개발팀  
**프로젝트 상태**: ✅ 정상 운영 중
