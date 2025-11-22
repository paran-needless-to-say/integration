# EC2 배포 진행 가이드 (현재 단계)

EC2 서버에 접속한 상태에서 배포를 진행하는 단계별 가이드입니다.

---

## 현재 상태

✅ **1단계: 서버 접속** - 완료!
- SSH 접속 성공
- 터미널 프롬프트: `ubuntu@ip-172-31-54-70:~$`

---

## 2단계: 필수 소프트웨어 설치

EC2 서버의 터미널에서 다음 명령어를 실행하세요:

```bash
# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker 그룹 적용 (현재 세션에 반영)
newgrp docker

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Git 설치 (이미 설치되어 있을 수 있음)
sudo apt-get install git -y

# 설치 확인
docker --version
docker-compose --version
git --version
```

**예상 출력**:
```
Docker version 24.x.x
Docker Compose version v2.x.x
git version 2.x.x
```

⏱️ **예상 소요 시간**: 5-10분

---

## 3단계: 프로젝트 클론

```bash
# 홈 디렉토리로 이동
cd ~

# 통합 레포 클론
git clone https://github.com/paran-needless-to-say/integration.git trace-x
cd trace-x

# 최신 코드 확인
git pull origin main
```

⏱️ **예상 소요 시간**: 1-2분

---

## 4단계: 환경 변수 설정

```bash
# .env 파일 생성
cat > .env << EOF
# Etherscan API 키 (필수) - 반드시 실제 키로 변경하세요!
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Flask 환경
FLASK_ENV=production

# Python 출력 버퍼링 비활성화
PYTHONUNBUFFERED=1

# 백엔드 API URL (프론트엔드에서 사용)
VITE_BACKEND_API_URL=http://3.35.164.184:8888

# 리스크 스코어링 API URL (백엔드에서 사용, Docker 네트워크 내부)
RISK_SCORING_API_URL=http://risk-scoring:5001
EOF

# Etherscan API 키를 실제 키로 변경
nano .env
```

**중요**: 
- `your_etherscan_api_key_here`를 **실제 Etherscan API 키**로 변경하세요!
- `3.35.164.184`를 **본인의 EC2 서버 IP**로 변경하세요!

**nano 에디터 사용법**:
- 키 입력으로 이동
- `Ctrl + X` → `Y` → `Enter` (저장 후 종료)

⏱️ **예상 소요 시간**: 1분

---

## 5단계: 배포 실행

```bash
# 배포 스크립트 실행 권한 부여
chmod +x scripts/deploy.sh

# 배포 실행
./scripts/deploy.sh
```

배포 스크립트가 자동으로:
1. 환경 변수 확인
2. Docker 이미지 빌드
3. 컨테이너 시작
4. Health check 실행

⏱️ **예상 소요 시간**: 5-10분 (첫 빌드 시 더 오래 걸릴 수 있음)

---

## 배포 완료 확인

### 서비스 상태 확인

```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f
```

### Health Check

```bash
# Risk Scoring API
curl http://localhost:5001/health

# Backend API
curl http://localhost:8888/api/dashboard/summary

# Frontend (브라우저에서)
# http://your-server-ip:5173
```

---

## 문제 해결

### Docker 명령어가 실행되지 않음

```bash
# Docker 그룹 다시 적용
newgrp docker

# 또는 SSH 재접속
exit
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@your-server-ip
```

### Git 클론 실패

```bash
# Git 설치 확인
which git

# Git 설치
sudo apt-get install git -y
```

### .env 파일 수정 방법

```bash
# nano 에디터로 수정
nano .env

# 또는 vi 에디터로 수정
vi .env

# 또는 cat으로 내용 확인
cat .env
```

---

## 다음 단계

배포가 완료되면:
1. 브라우저에서 `http://your-server-ip:5173` 접속
2. "Ad-hoc Analysis" 메뉴에서 주소 입력 및 분석 테스트
3. 모든 서비스가 정상 작동하는지 확인

---

## 전체 명령어 한 번에 복사하기

```bash
# 2단계: 필수 소프트웨어 설치
sudo apt-get update && sudo apt-get upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER && newgrp docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt-get install git -y
docker --version && docker-compose --version && git --version

# 3단계: 프로젝트 클론
cd ~ && git clone https://github.com/paran-needless-to-say/integration.git trace-x
cd trace-x && git pull origin main

# 4단계: 환경 변수 설정 (.env 파일 생성 후 Etherscan API 키 입력 필요!)
# (이 부분은 수동으로 수정해야 함)

# 5단계: 배포 실행
chmod +x scripts/deploy.sh && ./scripts/deploy.sh
```

---

**지금 EC2 서버 터미널에서 2단계부터 시작하세요!** 🚀

