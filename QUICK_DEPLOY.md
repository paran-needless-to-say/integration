# Trace-X 빠른 EC2 배포 가이드

EC2 서버에 직접 접속해서 통합 배포하는 빠른 가이드입니다.

## 준비 사항

### 1. EC2 서버 정보

다음 정보를 준비하세요:

- **서버 IP 주소**: AWS 콘솔에서 확인
- **SSH 키 파일**: `.pem` 파일 (경로)
- **사용자명**: 보통 `ubuntu` 또는 `ec2-user`
- **Etherscan API 키**: 이미 발급받은 키

### 2. EC2 서버 접속 방법

#### AWS 콘솔에서 서버 정보 확인

1. **AWS 콘솔 접속**: https://console.aws.amazon.com
2. **EC2 대시보드** → **인스턴스** 메뉴
3. 인스턴스 선택 → **퍼블릭 IPv4 주소** 확인
   - 예: `54.123.45.67` 또는 `ec2-54-123-45-67.compute-1.amazonaws.com`

#### SSH로 접속하기

**1단계: SSH 키 파일 권한 설정**

```bash
# 로컬 터미널에서 실행 (반드시 필요!)
chmod 400 your-key.pem
```

**2단계: SSH 접속 명령어**

**Ubuntu 인스턴스인 경우:**

```bash
ssh -i your-key.pem ubuntu@your-server-ip
```

**Amazon Linux 인스턴스인 경우:**

```bash
ssh -i your-key.pem ec2-user@your-server-ip
```

**예시:**

```bash
# 키 파일이 ~/Downloads/my-key.pem이고 IP가 54.123.45.67인 경우
ssh -i ~/Downloads/my-key.pem ubuntu@54.123.45.67
```

#### 접속 성공 확인

접속이 성공하면 다음과 같이 표시됩니다:

```
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-1105-aws x86_64)
...
ubuntu@ip-172-31-xx-xx:~$
```

이제 EC2 서버에 접속된 상태입니다!

---

## 빠른 배포 (5단계)

### 1단계: 서버 접속

위의 "EC2 서버 접속 방법"을 따라 서버에 접속하세요.

```bash
ssh -i your-key.pem ubuntu@your-server-ip
```

### 2단계: 필수 소프트웨어 설치

```bash
# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Git 설치
sudo apt-get install git -y

# 설치 확인
docker --version
docker-compose --version
git --version
```

### 3단계: 프로젝트 클론

```bash
# 홈 디렉토리로 이동
cd ~

# 통합 레포 클론
git clone https://github.com/paran-needless-to-say/integration.git trace-x
cd trace-x

# 최신 코드 확인
git pull origin main
```

### 4단계: 환경 변수 설정

```bash
# .env 파일 생성
cat > .env << EOF
# Etherscan API 키 (필수)
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Flask 환경
FLASK_ENV=production

# Python 출력 버퍼링 비활성화
PYTHONUNBUFFERED=1

# 백엔드 API URL (프론트엔드에서 사용)
VITE_BACKEND_API_URL=http://your-server-ip:8888

# 리스크 스코어링 API URL (백엔드에서 사용, Docker 네트워크 내부)
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF

# Etherscan API 키를 실제 키로 변경
nano .env  # 또는 원하는 에디터 사용
```

**중요**: `your_etherscan_api_key_here`를 실제 Etherscan API 키로 변경하세요!

### 5단계: 배포 실행

```bash
# 배포 스크립트 실행 권한 부여
chmod +x scripts/deploy.sh

# 배포 실행
./scripts/deploy.sh
```

배포가 완료되면 자동으로 health check를 실행합니다.

---

## 배포 확인

### 서비스 상태 확인

```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f
```

### API 테스트

```bash
# 백엔드 API 확인
curl http://localhost:8888/api/dashboard/summary

# 리스크 스코어링 API 확인
curl http://localhost:5001/health

# 프론트엔드 확인
curl -I http://localhost:5173

# 리스크 스코어링 분석 테스트
curl "http://localhost:8888/api/analysis/risk-scoring?chain_id=1&address=0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be&hop_count=2"
```

외부에서 접속:

```bash
# 서버 IP로 테스트 (로컬에서 실행)
curl http://your-server-ip:8888/api/dashboard/summary
curl http://your-server-ip:5173
```

---

## 문제 해결

### Docker가 설치되지 않음

```bash
# Docker 재설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인
exit
ssh -i your-key.pem ubuntu@your-server-ip
```

### 포트가 이미 사용 중

```bash
# 포트 사용 중인 프로세스 확인
sudo lsof -i :8888
sudo lsof -i :5001
sudo lsof -i :5173

# 프로세스 종료 (필요 시)
sudo kill -9 <PID>
```

### 컨테이너가 시작되지 않음

```bash
# 로그 확인
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs risk-scoring
docker-compose -f docker-compose.prod.yml logs frontend

# 컨테이너 재시작
docker-compose -f docker-compose.prod.yml restart
```

### .env 파일 문제

```bash
# .env 파일 확인
cat .env

# .env 파일 재생성
cat > .env << EOF
ETHERSCAN_API_KEY=실제_키_입력
FLASK_ENV=production
PYTHONUNBUFFERED=1
VITE_BACKEND_API_URL=http://your-server-ip:8888
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF

# 서비스 재시작
docker-compose -f docker-compose.prod.yml restart
```

---

## 서비스 관리 명령어

```bash
cd ~/trace-x

# 서비스 시작
docker-compose -f docker-compose.prod.yml up -d

# 서비스 중지
docker-compose -f docker-compose.prod.yml down

# 서비스 재시작
docker-compose -f docker-compose.prod.yml restart

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f

# 특정 서비스 로그만 확인
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f risk-scoring
docker-compose -f docker-compose.prod.yml logs -f frontend

# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 최신 코드로 업데이트
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## 다음 단계

배포가 완료되면:

1. **보안 그룹 설정 확인**: 포트 8888, 5001, 5173이 열려있는지 확인
2. **Nginx 설정** (선택): 도메인 연결 및 SSL 인증서 설치
3. **모니터링 설정** (선택): 로그 수집 및 알림 설정

자세한 내용은 [DEPLOYMENT.md](./docs/DEPLOYMENT.md)를 참조하세요.

---

## 도움이 필요하신가요?

- [DEPLOYMENT.md](./docs/DEPLOYMENT.md): 상세 배포 가이드
- [API_USAGE.md](./docs/API.md): API 사용 방법
- [GitHub Issues](https://github.com/paran-needless-to-say/integration/issues)
