# EC2 새 인스턴스 생성 및 접속 가이드

새 EC2 인스턴스를 생성하고 접속하는 방법입니다.

---

## 1단계: EC2 인스턴스 생성

### AWS 콘솔에서 인스턴스 시작

1. **AWS 콘솔 접속**: https://console.aws.amazon.com
2. **EC2 → 인스턴스** 메뉴
3. **"인스턴스 시작"** 버튼 클릭

### 인스턴스 설정

#### 1. 이름 및 태그

- **이름**: `trace-x` (또는 원하는 이름)

#### 2. 애플리케이션 및 OS 이미지 (AMI)

- **Ubuntu Server 22.04 LTS** 또는 **20.04 LTS** 선택 (권장)
- 또는 **Amazon Linux 2023** 선택 가능

#### 3. 인스턴스 유형

- **테스트/개발**: `t3.small` (2 vCPU, 2GB RAM) - 무료 티어 가능
- **프로덕션**: `t3.medium` (2 vCPU, 4GB RAM) 이상 권장
- **고성능**: `m7i-flex.large` (4 vCPU, 8GB RAM)

#### 4. 키 페어 (로그인)

- **"새 키 페어 생성"** 선택
- **키 페어 이름**: `trace-x-key` (또는 원하는 이름)
- **키 페어 유형**: `RSA`
- **프라이빗 키 파일 형식**: `.pem`
- **"키 페어 생성"** 클릭
- **⚠️ 중요**: `.pem` 파일이 자동으로 다운로드됩니다. **안전한 곳에 저장하세요!**

#### 5. 네트워크 설정

- **퍼블릭 IP 자동 할당**: `사용` (또는 `활성화`)
- **방화벽 (보안 그룹) 규칙**:
  - **SSH (22)**: `내 IP` 또는 `0.0.0.0/0` (임시)
  - **HTTP (80)**: `0.0.0.0/0`
  - **HTTPS (443)**: `0.0.0.0/0` (SSL 사용 시)
  - **커스텀 TCP (8888)**: `0.0.0.0/0` (Backend API)
  - **커스텀 TCP (5001)**: `0.0.0.0/0` (Risk Scoring API)
  - **커스텀 TCP (5173)**: `0.0.0.0/0` (Frontend - 개발 환경)

#### 6. 스토리지

- **볼륨 크기**: 20GB 이상 권장 (프로덕션은 30GB+)
- **볼륨 유형**: `gp3` (권장)

#### 7. 고급 세부 정보 (선택)

- **IAM 역할**: 없어도 됨 (Session Manager 사용 시 필요)

### 인스턴스 시작

1. **"인스턴스 시작"** 버튼 클릭
2. 인스턴스가 생성되면 **"모든 인스턴스 보기"** 클릭
3. 인스턴스 상태가 **"실행 중"**이 될 때까지 대기 (1-2분)

---

## 2단계: 인스턴스 정보 확인

### AWS 콘솔에서 확인

1. **EC2 → 인스턴스** 메뉴
2. 생성한 인스턴스 선택
3. 하단 세부 정보에서 다음 정보 확인:
   - **퍼블릭 IPv4 주소**: `3.35.164.184` (예시)
   - **인스턴스 ID**: `i-xxxxxxxxxxxxx`
   - **키 페어 이름**: `trace-x-key` (생성한 이름)

---

## 3단계: 키 페어 파일 준비

### 다운로드한 키 파일 확인

다운로드 폴더에서 `.pem` 파일을 찾으세요:

```bash
# 다운로드 폴더 확인
ls -la ~/Downloads/*.pem

# 또는 데스크톱 확인
ls -la ~/Desktop/*.pem
```

### 키 파일 권한 설정

**⚠️ 중요**: SSH 접속 전에 반드시 키 파일 권한을 설정해야 합니다.

```bash
# 키 파일 경로로 이동 (예시)
cd ~/Downloads

# 권한 설정 (읽기 전용)
chmod 400 trace-x-key.pem

# 권한 확인
ls -l trace-x-key.pem
# 출력: -r-------- 1 user user 1674 ... trace-x-key.pem (400 권한)
```

---

## 4단계: SSH 접속

### Ubuntu 인스턴스인 경우

```bash
# 기본 형식
ssh -i ~/Downloads/trace-x-key.pem ubuntu@your-server-ip

# 예시
ssh -i ~/Downloads/trace-x-key.pem ubuntu@3.35.164.184
```

### Amazon Linux 인스턴스인 경우

```bash
# 기본 형식
ssh -i ~/Downloads/trace-x-key.pem ec2-user@your-server-ip

# 예시
ssh -i ~/Downloads/trace-x-key.pem ec2-user@3.35.164.184
```

### 접속 성공 확인

접속이 성공하면 다음과 같이 표시됩니다:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1048-aws x86_64)
...
ubuntu@ip-172-31-xx-xx:~$
```

이제 EC2 서버에 접속된 상태입니다!

---

## 5단계: 접속 후 첫 설정

### 시스템 업데이트

```bash
# Ubuntu인 경우
sudo apt-get update
sudo apt-get upgrade -y

# Amazon Linux인 경우
sudo yum update -y
```

### 필수 소프트웨어 설치

```bash
# Git 설치
sudo apt-get install git -y  # Ubuntu
# 또는
sudo yum install git -y  # Amazon Linux

# 설치 확인
git --version
```

---

## 6단계: 배포 진행

이제 [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)의 **2단계**부터 진행하세요:

1. **필수 소프트웨어 설치** (Docker, Docker Compose)
2. **프로젝트 클론**
3. **환경 변수 설정**
4. **배포 실행**

---

## 문제 해결

### SSH 접속 실패: "Permission denied (publickey)"

**원인**: 키 파일 권한이 잘못되었거나 키 파일 경로가 틀림

**해결**:

```bash
# 키 파일 권한 확인
ls -l ~/Downloads/trace-x-key.pem

# 권한 설정 (400이어야 함)
chmod 400 ~/Downloads/trace-x-key.pem

# 다시 접속 시도
ssh -i ~/Downloads/trace-x-key.pem ubuntu@your-server-ip
```

### SSH 접속 실패: "Connection timed out"

**원인**: 보안 그룹에서 SSH(22) 포트가 열려있지 않음

**해결**:

1. AWS 콘솔 → EC2 → 인스턴스
2. 인스턴스 선택 → "보안" 탭
3. 보안 그룹 클릭 → "인바운드 규칙" 편집
4. 규칙 추가:
   - 유형: `SSH`
   - 포트: `22`
   - 소스: `내 IP` 또는 `0.0.0.0/0`
5. 규칙 저장

### 키 페어 파일을 잃어버림

**⚠️ 중요**: 키 페어 파일은 복구할 수 없습니다. 새 키 페어를 사용하려면 인스턴스를 재생성해야 합니다.

**해결 방법**:

1. 인스턴스에서 AMI(이미지) 생성
2. 새 인스턴스 시작 (새 키 페어 사용)
3. 또는 Session Manager 사용 (IAM 역할 필요)

---

## 보안 권장사항

### SSH 접속 보안 강화

1. **보안 그룹 제한**:

   - SSH(22) 포트: `내 IP`만 허용 (프로덕션)
   - `0.0.0.0/0`은 테스트 환경에서만 사용

2. **키 파일 보관**:

   - `.pem` 파일은 안전한 곳에 보관
   - Git에 커밋하지 않음 (이미 `.gitignore`에 포함)

3. **인스턴스 보안**:
   - 정기적으로 시스템 업데이트
   - 불필요한 포트 닫기
   - 방화벽 설정 (ufw 또는 iptables)

---

## 다음 단계

1. ✅ 인스턴스 생성 완료
2. ✅ SSH 접속 완료
3. ➡️ [QUICK_DEPLOY.md](./QUICK_DEPLOY.md) 2단계부터 배포 진행

---

## 참고 문서

- [빠른 배포 가이드](./QUICK_DEPLOY.md): 배포 5단계
- [프로덕션 배포 가이드](./docs/DEPLOYMENT.md): 상세 배포 가이드
- [키 없이 접속하기](./EC2_ACCESS_WITHOUT_KEY.md): Session Manager 사용법
