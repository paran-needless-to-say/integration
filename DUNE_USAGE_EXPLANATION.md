# Dune API 사용 여부 설명

## 질문: "내부 로직에서 Dune을 사용하셨나요?"

### 답변

**리스크 스코어링 API에는 Dune을 사용하지 않습니다.**

리스크 스코어링 API는 **완전히 독립적인 자체 로직**으로 동작합니다.

---

## 상세 설명

### 리스크 스코어링 API (risk-scoring)

✅ **Dune 사용 안 함**

리스크 스코어링 API는 다음과 같이 동작합니다:

1. **TRACE-X 룰북 기반 규칙 평가**
   - 50개 이상의 AML 규칙으로 위험도 평가
   - 룰 파일: `rules/tracex_rules.yaml`

2. **OFAC SDN 리스트 사용**
   - 제재 대상 주소 검증
   - 로컬 파일: `data/lists/sdn_addresses.json`

3. **그래프 패턴 분석**
   - NetworkX를 사용한 거래 관계 그래프 분석
   - Layering Chain, Cycle 등 패턴 탐지

4. **백엔드에서 받은 데이터 기반 분석**
   - 백엔드가 수집한 거래 데이터를 받아서 처리
   - 자체적인 외부 API 호출 없음

### 백엔드 (backend) - 별도

⚠️ **백엔드는 Dune을 사용합니다** (리스크 스코어링과는 별개)

백엔드의 `/api/dashboard/monitoring` 엔드포인트에서만 사용:

```python
# backend/src/api/dashboard.py
from src.api.dashboard import get_dune_results

@app.route('/api/dashboard/monitoring', methods=['GET'])
def get_dashboard_monitoring():
    rows = get_dune_results()  # Dune API 호출
    # 대시보드 모니터링용 고액 거래 데이터
```

**용도:**
- 대시보드 모니터링 기능
- 고액 거래 데이터 표시
- 리스크 스코어링과는 무관

**환경 변수:**
- `DUNE_API_KEY` 필요 (백엔드에서만 사용)

---

## 요약

| 컴포넌트 | Dune 사용 여부 | 용도 |
|---------|--------------|------|
| **리스크 스코어링 API** | ❌ 사용 안 함 | 완전히 독립적인 자체 로직 |
| **백엔드** | ✅ 사용함 | 대시보드 모니터링 기능만 |

**백엔드 팀에게 전달할 메시지:**

> "리스크 스코어링 API 내부 로직에는 Dune을 사용하지 않습니다. 
> 리스크 스코어링은 TRACE-X 룰북 기반의 자체 로직으로만 동작하며, 
> 백엔드에서 전달한 거래 데이터를 분석하여 위험도를 평가합니다.
> 
> 다만, 백엔드 자체의 `/api/dashboard/monitoring` 엔드포인트에서는 
> Dune API를 사용하여 대시보드 모니터링 데이터를 가져옵니다. 
> 이는 리스크 스코어링 기능과는 별개입니다."

---

## 참고

- 리스크 스코어링 API는 외부 데이터 소스에 의존하지 않습니다
- 모든 분석은 백엔드에서 제공한 거래 데이터와 로컬 룰북/리스트로 수행됩니다
- Dune API 키가 없어도 리스크 스코어링 API는 정상 작동합니다

