# ⚡ Trace-X Quick Start

## 🎯 30초 안에 시작하기

### 1. 환경 변수 설정

```bash
cd trace-x
echo "ETHERSCAN_API_KEY=your_api_key_here" > .env
```

### 2. 실행

```bash
./scripts/start-all.sh
```

### 3. 접속

브라우저에서 [http://localhost:5173](http://localhost:5173) 열기

### 4. 테스트

1. "Adhoc Analysis" 메뉴 클릭
2. 주소 입력: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`
3. "분석하기" 클릭
4. 결과 확인! 🎉

---

## 🐳 Docker로 실행 (더 쉬움)

```bash
export ETHERSCAN_API_KEY=your_api_key_here
docker-compose up
```

---

## 🛑 중지

```bash
./scripts/stop-all.sh
```

---

## 🏥 상태 확인

```bash
./scripts/health-check.sh
```

---

## 🧪 통합 테스트

```bash
./scripts/test-integration.sh
```

---

## 📚 더 알아보기

- [전체 문서](README.md)
- [통합 가이드](docs/INTEGRATION_GUIDE.md)
- [API 문서](docs/API.md)
- [문제 해결](README.md#문제-해결)

---

## 💡 자주 하는 실수

### ❌ Etherscan API 키를 설정하지 않음

```bash
# .env 파일 확인
cat .env

# 없으면 생성
echo "ETHERSCAN_API_KEY=your_key" > .env
```

### ❌ 포트가 이미 사용 중

```bash
# 기존 프로세스 중지
./scripts/stop-all.sh

# 다시 시작
./scripts/start-all.sh
```

### ❌ Risk Scoring API가 시작되지 않음

```bash
# 가상환경 확인
cd risk-scoring
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python run_server.py
```

---

**이제 시작할 준비가 됐어요! 🚀**
