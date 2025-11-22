# 📦 100end 통합 요약

백엔드 팀을 위한 리스크 스코어링 API 연동 통합 요약 문서입니다.

---

## ✅ 통합 완료 항목

### 1. 필요한 파일

#### 새로 추가할 파일

- `src/api/risk_scoring.py` - 리스크 스코어링 API 연동 모듈

#### 수정할 파일

- `src/app.py` - `/api/analysis/risk-scoring` 엔드포인트 추가
- `pyproject.toml` 또는 `requirements.txt` - `requests>=2.28.0` 추가

---

## 🔧 빠른 통합 가이드

### 1단계: 파일 추가

`src/api/risk_scoring.py` 파일을 `100end/src/api/` 폴더에 추가하세요.

### 2단계: 의존성 추가

`pyproject.toml`에 추가:

```toml
dependencies = [
    # ... 기존 의존성 ...
    "requests>=2.28.0",
]
```

또는 `requirements.txt`에 추가:

```txt
requests>=2.28.0
```

### 3단계: `src/app.py` 수정

#### import 추가

```python
from src.api.risk_scoring import analyze_address_with_risk_scoring
```

#### 엔드포인트 추가

`/api/analysis/risk-scoring` 엔드포인트를 추가하세요.
(자세한 코드는 [100END_INTEGRATION_GUIDE.md](./100END_INTEGRATION_GUIDE.md) 참고)

### 4단계: 환경 변수 설정

EC2에서 실행 시:

```bash
export RISK_SCORING_API_URL=http://localhost:5001
```

---

## 🚀 배포 체크리스트

- [ ] `src/api/risk_scoring.py` 파일 추가
- [ ] `src/app.py`에 엔드포인트 추가
- [ ] `requests` 패키지 설치 확인
- [ ] `RISK_SCORING_API_URL` 환경 변수 설정
- [ ] 리스크 스코어링 API 실행 확인 (포트 5001)
- [ ] 백엔드 서버 재시작
- [ ] `/api/analysis/risk-scoring` 엔드포인트 테스트

---

## 📚 상세 문서

- [100end 통합 가이드](./100END_INTEGRATION_GUIDE.md) - 전체 통합 가이드
- [API 사용 방법](./100END_API_USAGE.md) - API 사용 예시 및 상세 설명

---

## 🤝 문의

통합 과정에서 문제가 발생하면 백엔드 팀이나 예림님께 문의해주세요!
