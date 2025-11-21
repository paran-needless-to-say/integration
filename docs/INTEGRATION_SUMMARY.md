# 🎉 프론트엔드-백엔드-리스크 스코어링 통합 완료!

## ✅ 완료된 작업

### 1. 백엔드 (100end)

#### 새로운 파일:

- **`src/api/risk_scoring.py`**: 리스크 스코어링 API 연동 모듈
  - `convert_graph_to_transactions()`: 그래프 데이터를 거래 배열로 변환
  - `call_risk_scoring_api()`: 리스크 스코어링 API 호출
  - `analyze_address_with_risk_scoring()`: 전체 플로우 통합

#### 수정된 파일:

- **`src/app.py`**:
  - `/api/analysis/risk-scoring` 엔드포인트 추가
  - Multi-hop 데이터 수집 + 리스크 스코어링 통합

#### 새로운 API 엔드포인트:

```
POST /api/analysis/risk-scoring
{
  "address": "0x...",
  "chain_id": 1,
  "max_hops": 3,
  "analysis_type": "basic" | "advanced"
}
```

---

### 2. 프론트엔드 (frontend)

#### 새로운 파일:

- **`src/services/backend.ts`**: 백엔드 API 서비스
  - `analyzeAddressViaBackend()`: 백엔드를 통한 리스크 스코어링
  - `getFundFlow()`: 펀드 플로우 조회
  - `getMultihopGraphData()`: Multi-hop 그래프 데이터 조회

#### 수정된 파일:

- **`src/pages/adhoc/index.tsx`**:
  - 백엔드 API 사용으로 전환
  - 체인 선택 기능 추가 (Ethereum, BSC, Polygon)
  - 1-hop 기본 분석 / 3-hop 심층 분석 구분

---

### 3. 문서화

#### 새로운 문서:

1. **`INTEGRATION_GUIDE.md`**: 전체 시스템 통합 가이드

   - 시스템 구조
   - 환경 설정
   - 실행 방법
   - API 플로우
   - 트러블슈팅

2. **`frontend/BACKEND_INTEGRATION.md`**: 백엔드 연동 가이드 (업데이트)

   - 완료된 작업 목록
   - API 사용법
   - 테스트 방법

3. **`100end/README.md`**: 백엔드 README (업데이트)
   - API 엔드포인트 상세 설명
   - 환경 설정
   - 트러블슈팅

---

## 🔄 데이터 플로우

```
[프론트엔드: localhost:5173]
  사용자가 주소 입력 (0x...)
  체인 선택 (Ethereum/BSC/Polygon)
  "분석하기" 버튼 클릭
    ↓
  POST /api/analysis/risk-scoring
  {
    "address": "0x...",
    "chain_id": 1,
    "max_hops": 1,
    "analysis_type": "basic"
  }

[백엔드: localhost:8888]
  1. Etherscan API로 거래 데이터 수집
     - get_multihop_fund_flow_for_scoring()
     - 1-hop 또는 3-hop 재귀 수집

  2. 그래프 데이터를 거래 배열로 변환
     - convert_graph_to_transactions()

  3. 리스크 스코어링 API 호출
    ↓
  POST http://localhost:5001/api/analyze/address
  {
    "address": "0x...",
    "chain_id": 1,
    "transactions": [...],
    "analysis_type": "basic"
  }

[리스크 스코어링 API: localhost:5001]
  1. 거래 데이터 분석
  2. 룰 평가 (B-101, D-102, B-201, B-202 등)
  3. 스코어 계산
  4. 결과 반환
    ↓
  {
    "target_address": "0x...",
    "risk_score": 85,
    "risk_level": "high",
    "fired_rules": [...],
    "risk_tags": [...],
    "explanation": "..."
  }

[백엔드 → 프론트엔드]
  결과를 프론트로 전달
    ↓
[프론트엔드]
  분석 결과 시각화
  - 리스크 스코어
  - 리스크 레벨
  - 발동된 룰
  - 리스크 태그
  - 설명
```

---

## 🚀 실행 방법

### 터미널 3개 필요:

#### Terminal 1: 리스크 스코어링 API

```bash
cd Cryptocurrency-Graphs-of-graphs
source venv/bin/activate
python run_server.py
```

✅ 확인: `http://localhost:5001/health`

#### Terminal 2: 백엔드

```bash
cd 100end
export ETHERSCAN_API_KEY=your_api_key
python3 main.py
```

✅ 확인: 8888 포트에서 실행 중

#### Terminal 3: 프론트엔드

```bash
cd frontend
npm run dev
```

✅ 확인: `http://localhost:5173`

---

## 🧪 테스트 시나리오

### 1. 기본 분석 (1-hop)

1. 브라우저에서 `http://localhost:5173` 접속
2. "Adhoc Analysis" 메뉴 클릭
3. 체인 선택: **Ethereum**
4. 주소 입력: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`
5. "분석하기" 클릭
6. 결과 확인:
   - ✅ 리스크 스코어 표시
   - ✅ 리스크 레벨 표시
   - ✅ 발동된 룰 목록
   - ✅ 리스크 태그

### 2. 심층 분석 (3-hop)

1. 기본 분석 완료 후
2. "심층 분석 (3-hop)" 버튼 클릭
3. 추가 결과 확인:
   - ✅ 3-hop까지 분석된 결과
   - ✅ 기본 분석과 비교 (스코어 차이, 추가된 룰)
   - ✅ B-201 (Layering Chain), B-202 (Cycle) 룰 작동

---

## 🎯 주요 기능

### 1. Multi-hop 데이터 수집

백엔드가 Etherscan API를 사용하여:

- **1-hop**: 대상 주소의 직접 거래만 수집 (빠름)
- **3-hop**: 대상 → 상대방 → 상대방의 상대방 (느림, 더 정확)

### 2. 체인 지원

- ✅ Ethereum (chain_id: 1)
- ✅ BSC (chain_id: 56)
- ✅ Polygon (chain_id: 137)

### 3. 분석 타입

- **Basic**: 기본 룰만 평가 (빠름)
- **Advanced**: 토폴로지 룰 포함 (느림, B-201, B-202)

---

## 🔧 주요 변경 사항

### 백엔드

#### Before:

```python
# /api/analysis/scoring - 그래프 데이터만 반환
return jsonify({'data': graph_data}), 200
```

#### After:

```python
# /api/analysis/risk-scoring - 리스크 스코어링 통합
graph_data = analyzer.get_multihop_fund_flow_for_scoring(...)
result = analyze_address_with_risk_scoring(...)  # 리스크 스코어링 API 호출
return jsonify({'data': result}), 200
```

### 프론트엔드

#### Before:

```typescript
// 거래 데이터를 직접 제공 (빈 배열)
const result = await analyzeAddress({
  address: "0x...",
  chain: "ethereum",
  transactions: [], // TODO: 백엔드에서 가져와야 함
});
```

#### After:

```typescript
// 백엔드를 통한 자동 수집
const result = await analyzeAddressViaBackend({
  address: "0x...",
  chain_id: 1,
  max_hops: 1,
  analysis_type: "basic",
});
```

---

## 📊 성능 고려사항

### 분석 시간 예상:

| 분석 타입 | Hop 수 | 예상 시간 | 설명                                          |
| --------- | ------ | --------- | --------------------------------------------- |
| 기본 분석 | 1-hop  | ~5초      | Etherscan API 호출 1회                        |
| 심층 분석 | 3-hop  | ~15-30초  | Etherscan API 호출 여러 번 + 그래프 패턴 탐지 |

### 최적화 고려사항:

- ✅ **캐싱**: 동일 주소 재분석 시 캐시 사용
- ✅ **병렬 처리**: 여러 주소의 거래 데이터 동시 수집
- ✅ **Rate Limiting**: Etherscan API 호출 제한 준수

---

## 🐛 알려진 이슈 및 해결 방법

### 1. Etherscan API Rate Limit

**증상**: `Too Many Requests` 에러

**해결**:

- 무료 API 키: 초당 5 요청 제한
- 유료 API 키 사용 권장
- 캐싱 활성화

### 2. 리스크 스코어링 API 타임아웃

**증상**: `Request timeout` 에러

**해결**:

- `max_hops`를 1 또는 2로 줄이기
- `max_addresses_per_direction`을 5 또는 10으로 제한

### 3. CORS 에러

**증상**: 프론트에서 백엔드 호출 시 CORS 에러

**해결**:

```python
# 100end/src/app.py
CORS(app, origins=["http://localhost:5173", "https://your-frontend-url.com"])
```

---

## 📚 참고 문서

- [통합 가이드](INTEGRATION_GUIDE.md)
- [백엔드 README](100end/README.md)
- [프론트엔드 연동 가이드](frontend/BACKEND_INTEGRATION.md)
- [리스크 스코어링 README](Cryptocurrency-Graphs-of-graphs/README.md)

---

## 🎉 결론

✅ **프론트엔드 ↔ 백엔드 ↔ 리스크 스코어링 API** 완전 통합 완료!

이제 사용자는:

1. 주소를 입력하고
2. 체인을 선택하고
3. "분석하기" 버튼을 누르면
4. 백엔드가 자동으로 거래 데이터를 수집하고
5. 리스크 스코어링 API가 분석하여
6. 결과를 프론트에 표시합니다!

**추가 개발 없이 바로 사용 가능합니다! 🚀**

---

## 다음 단계 (선택 사항)

- [ ] 거래 그래프 시각화 (D3.js)
- [ ] 분석 히스토리 저장 (LocalStorage)
- [ ] 다중 주소 동시 분석
- [ ] 실시간 알림 (WebSocket)
- [ ] 보고서 PDF 다운로드

---

**작성일**: 2025-11-21
**버전**: 1.0.0
**상태**: ✅ 완료
