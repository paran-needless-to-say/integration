# Trace-X 작품 요약

## 프로젝트 개요

**Trace-X: Blockchain Risk Analysis Platform**은 블록체인 주소의 거래 히스토리를 분석하여 AML(반세탁) 위험도를 실시간으로 평가하는 통합 플랫폼입니다.

---

## 핵심 가치

### 1. 혁신적인 2단계 하이브리드 아키텍처

- **1단계**: 규칙 기반 + 그래프 통계 스코어링 (해석 가능성 보장)
- **2단계**: 머신러닝 기반 최종 스코어링 (고성능 달성)
- **성과**: 해석 가능성을 유지하면서 정확도 **99.20%** 달성

### 2. 체계적인 룰북 시스템

- **22개의 룰**을 Compliance, Exposure, Behavior 3축으로 분류
- OFAC SDN 리스트, Chainalysis 보고서 등 권위 있는 자료 참고
- Multi-hop 분석을 통한 복잡한 세탁 패턴 탐지

### 3. 실시간 분석 능력

- **1-hop 기본 분석**: 약 1-5초 내 결과 제공 (실시간 대시보드 적합)
- **3-hop 심층 분석**: 약 15-30초 내 복잡한 패턴 탐지 (포렌식 분석)

---

## 시스템 구조

```
Frontend (React + TypeScript)
    ↓
Backend (Flask API) - 거래 데이터 수집
    ↓
Risk Scoring API (Python + NetworkX) - 리스크 분석
    ↓
결과 반환 및 시각화
```

### 주요 컴포넌트

1. **Frontend** (포트 5173)

   - React 19, TypeScript, Vite
   - SoCar UI/UX 기반 디자인
   - 실시간 그래프 시각화, Dashboard, Live Detection

2. **Backend** (포트 8888)

   - Flask, Python 3.10+
   - Etherscan API를 통한 거래 데이터 수집
   - Multi-hop 그래프 데이터 생성

3. **Risk Scoring API** (포트 5001)
   - Flask, Python 3.10+, NetworkX, scikit-learn
   - 2단계 하이브리드 스코어링 엔진
   - 룰북 기반 평가 및 그래프 패턴 탐지

---

## 주요 기능

### 1. Multi-hop 거래 분석

- 1-hop: 직접 거래 상대방 분석
- 2-hop: 1단계 상대방의 거래 분석
- 3-hop: 2단계 상대방의 거래 분석
- 복잡한 자금 세탁 경로 추적 가능

### 2. 리스크 스코어링

- **0-100점 척도**로 위험도 정량화
- Compliance, Exposure, Behavior 3축 평가
- 22개 룰 기반 체계적 평가

### 3. 그래프 패턴 탐지

- **Layering Chain**: 다층 구조의 자금 이동
- **Cycle**: 순환 구조의 거래
- **Fan-in/Fan-out**: 집중/분산 패턴
- Personalized PageRank를 활용한 간접 제재 노출 탐지

### 4. Multi-chain 지원

- Ethereum, BSC, Polygon 등 여러 체인 지원
- 확장 가능한 구조로 설계

---

## 기술적 성과

### 성능 지표

- **Accuracy**: 99.20%
- **ROC-AUC**: 0.9992
- **Precision**: 0.9968
- **Recall**: 0.9841
- **F1-Score**: 0.9904

### 데이터셋

- Graph of Graphs (GOG) 논문 데이터셋 활용
- 92,138개의 라벨링된 이더리움 거래 데이터
- 학습 3,499개, 검증 749개, 테스트 752개

### 비교 평가

- 최신 모델들과 동등한 성능 (XGBoost, LightGBM, Random Forest와 동등)
- **차별화**: 해석 가능성 제공 (다른 모델들은 블랙박스)
- 선행 연구 모델들(OCGTL, GUDI, MACE 등) 대비 우수한 성능

---

## 핵심 혁신성

### 해석 가능성과 성능의 동시 달성

기존 시스템들이 해결하지 못한 **"해석 가능성과 성능 간 트레이드오프"**를 혁신적으로 해결:

- **블랙박스 모델들의 한계**: 높은 성능이지만 설명 불가능
- **순수 규칙 기반의 한계**: 해석 가능하지만 낮은 성능
- **제안 시스템**: 해석 가능성 + 최고 수준 성능 동시 달성

### 실무 적용 가능성

- 규제 환경에서 필수적인 **의사결정 근거 제공**
- 각 룰의 발동 이유를 명시적으로 제공
- 실시간 분석으로 운영 환경에 바로 적용 가능

---

## 활용 방안

### 1. 중앙화 거래소(CEX)

- 사용자 입금 전 리스크 평가
- 실시간 모니터링 및 차단 시스템

### 2. 규제 기관

- 암호화폐 자금세탁 탐지
- 의심 거래 조사 지원

### 3. 금융 기관

- 가상자산 관련 규제 준수
- 리스크 평가 및 보고서 작성

---

## 기술 스택

### Frontend

- React 19, TypeScript, Vite
- vis-network (그래프 시각화)

### Backend

- Flask, Python 3.10+
- Etherscan API 연동

### Risk Scoring API

- Flask, Python 3.10+
- NetworkX (그래프 분석)
- scikit-learn, XGBoost, LightGBM (머신러닝)
- YAML 기반 룰 정의

---

## 배포 현황

- **로컬 개발**: Docker Compose 지원
- **EC2 배포**: 프로덕션 환경 구축
- **API 문서**: Swagger UI 제공 (`/api-docs`)
- **웹 데모**: 인터랙티브 시각화 인터페이스 제공

---

## 주요 파일 및 문서

- **프로젝트 보고서**: `PROJECT_REPORT.md`
- **자기주도연구 템플릿**: `SELF_STUDY_TEMPLATE_SUMMARY.md`
- **API 문서**: `risk-scoring/docs/API_DOCUMENTATION.md`
- **룰북 상세**: `risk-scoring/docs/RULEBOOK_DETAILED.md`
- **성능 평가**: `risk-scoring/docs/PERFORMANCE_EVALUATION.md`

---

## 수상 포인트

1. **혁신적 아키텍처**: 2단계 하이브리드 시스템으로 해석 가능성과 성능 동시 달성
2. **우수한 성능**: 정확도 99.20%, ROC-AUC 0.9992로 최고 수준 성능
3. **실무 적용성**: 규제 환경에서 요구되는 해석 가능성 제공
4. **과학적 검증**: 대규모 실제 데이터셋 기반 성능 검증
5. **완성도 높은 구현**: 프론트엔드, 백엔드, 리스크 스코어링 API 통합 시스템

---

**Made with ❤️ by the Trace-X Team**
