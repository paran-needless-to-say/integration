# 환경 변수 설정 가이드

.env 파일을 생성하고 설정하는 방법입니다.

---

## 상황

EC2 메타데이터 서비스가 응답하지 않는 경우 (IMDSv2 설정 문제일 수 있음)

---

## 방법 1: AWS 콘솔에서 IP 확인 후 .env 파일 생성

### 1단계: AWS 콘솔에서 퍼블릭 IP 확인

1. **AWS 콘솔 접속**: https://console.aws.amazon.com
2. **EC2 → 인스턴스** 메뉴
3. 인스턴스 선택 (`Trace-X` 또는 `i-xxxxx`)
4. 하단 세부 정보에서 **"퍼블릭 IPv4 주소"** 확인
   - 예: `3.35.164.184`
   - 또는 `54.123.45.67`

### 2단계: .env 파일 생성

EC2 서버 터미널에서 다음 명령어를 실행하세요 (IP 주소를 본인의 것으로 변경):

```bash
# .env 파일 생성
cat > .env << 'EOF'
# Etherscan API 키 (필수) - 반드시 실제 키로 변경하세요!
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Flask 환경
FLASK_ENV=production

# Python 출력 버퍼링 비활성화
PYTHONUNBUFFERED=1

# 프론트엔드 빌드 시 사용 (VITE_ 접두사 필요 - 빌드 시점에 코드에 주입됨)
# EC2 서버의 퍼블릭 IP 주소로 변경하세요!
VITE_BACKEND_API_URL=http://YOUR_SERVER_IP:8888

# 백엔드 런타임 시 사용 (Docker 네트워크 내부 통신, VITE_ 접두사 불필요)
# 백엔드 컨테이너에서 리스크 스코어링 컨테이너로 접근할 때 사용
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF
```

**중요**: `YOUR_SERVER_IP`를 AWS 콘솔에서 확인한 실제 퍼블릭 IP로 변경하세요!

예시:

```bash
# IP가 3.35.164.184인 경우
cat > .env << 'EOF'
ETHERSCAN_API_KEY=your_etherscan_api_key_here
FLASK_ENV=production
PYTHONUNBUFFERED=1
VITE_BACKEND_API_URL=http://3.35.164.184:8888
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF
```

### 3단계: Etherscan API 키 입력

```bash
# nano 에디터로 .env 파일 열기
nano .env
```

nano 에디터 사용법:

1. 화살표 키로 이동
2. `your_etherscan_api_key_here`를 실제 Etherscan API 키로 변경
3. `YOUR_SERVER_IP`를 실제 서버 IP로 변경 (아직 안 바꿨다면)
4. `Ctrl + X` → `Y` → `Enter` (저장 후 종료)

---

## 방법 2: 일단 기본값으로 생성 후 나중에 수정

IP 주소를 모르거나 나중에 확인하고 싶다면, 일단 기본값으로 생성할 수 있습니다:

```bash
# .env 파일 생성 (기본값)
cat > .env << 'EOF'
# Etherscan API 키 (필수) - 반드시 실제 키로 변경하세요!
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Flask 환경
FLASK_ENV=production

# Python 출력 버퍼링 비활성화
PYTHONUNBUFFERED=1

# 백엔드 API URL (프론트엔드에서 사용) - 나중에 IP 주소로 변경 필요
VITE_BACKEND_API_URL=http://localhost:8888

# 리스크 스코어링 API URL (백엔드에서 사용, Docker 네트워크 내부)
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF
```

나중에 IP를 확인한 후 수정:

```bash
# .env 파일 수정
nano .env
# VITE_BACKEND_API_URL=http://localhost:8888 부분을
# VITE_BACKEND_API_URL=http://실제_서버_IP:8888 로 변경
```

---

## 방법 3: 다른 방법으로 IP 확인

### AWS CLI 사용 (AWS CLI가 설치되어 있는 경우)

```bash
# 인스턴스 ID 확인 (현재 서버에서)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
echo $INSTANCE_ID

# AWS CLI로 IP 확인 (AWS CLI가 설치되어 있고 설정되어 있는 경우)
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

### SSH 연결 정보에서 확인

로컬 터미널에서 SSH 연결 시 사용한 IP 주소를 확인:

```bash
# 로컬 터미널에서 (EC2 서버가 아닌 로컬)
# SSH 접속 시 사용한 명령어에서 IP 주소 확인
ssh -i ~/Desktop/paran_final/Paran_Trace-X.pem ubuntu@YOUR_IP_HERE
```

---

## .env 파일 확인

설정이 완료되었는지 확인:

```bash
# .env 파일 내용 확인
cat .env

# 예상 출력:
# ETHERSCAN_API_KEY=ABCD1234... (실제 키)
# FLASK_ENV=production
# PYTHONUNBUFFERED=1
# VITE_BACKEND_API_URL=http://3.35.164.184:8888 (실제 IP)
# RISK_SCORING_API_URL=http://risk-scoring:5001
```

---

## 문제 해결

### .env 파일이 없음

```bash
# 현재 디렉토리 확인
pwd
# 출력: /home/ubuntu/trace-x

# .env 파일 확인
ls -la .env

# 없으면 다시 생성
cat > .env << 'EOF'
...
EOF
```

### nano 에디터 사용 방법

```
- 화살표 키: 커서 이동
- Backspace/Delete: 문자 삭제
- Ctrl + X: 종료 (저장 여부 물어봄)
- Y: 저장 확인
- N: 저장하지 않음
- Enter: 확인
```

---

## 다음 단계

.env 파일 설정이 완료되면:

- ➡️ [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)의 **5단계: 배포 실행**을 진행하세요!
