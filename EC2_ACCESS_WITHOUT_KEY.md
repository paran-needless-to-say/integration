# EC2 인스턴스 접속 방법 (키 페어 없이)

EC2 인스턴스가 이미 실행 중이지만 키 페어(.pem 파일)를 모르는 경우의 해결 방법입니다.

## 상황 확인

이미 실행 중인 EC2 인스턴스:

- 인스턴스 ID: `i-05126306c48bfd8b3`
- 이름: `Trace-X`
- 퍼블릭 IP: `3.35.164.184`
- 상태: 실행 중

---

## 방법 1: AWS 콘솔에서 키 페어 이름 확인 (먼저 시도)

### 1단계: 인스턴스 세부 정보에서 키 페어 확인

1. AWS 콘솔 → EC2 → 인스턴스
2. 인스턴스 선택 (`i-05126306c48bfd8b3`)
3. 하단 세부 정보 패널 확인
4. **"키 페어 이름"** 또는 **"Key pair name"** 항목 확인
   - 예: `my-key`, `trace-x-key`, `paran-key` 등

### 2단계: 키 페어 파일 찾기

키 페어 이름을 확인했다면, 해당 이름의 `.pem` 파일을 찾아보세요:

```bash
# 일반적인 저장 위치
~/Downloads/
~/Desktop/
~/.ssh/
~/Downloads/*.pem
```

```bash
# 전체 시스템에서 검색 (느릴 수 있음)
find ~ -name "*.pem" -type f 2>/dev/null
```

### 3단계: 키 페어가 있다면 SSH 접속

```bash
# 키 파일 찾았다면
chmod 400 ~/Downloads/your-key.pem
ssh -i ~/Downloads/your-key.pem ubuntu@3.35.164.184
```

---

## 방법 2: AWS Systems Manager Session Manager 사용 (키 없이 접속) ✅ 권장

Session Manager를 사용하면 키 페어 없이 브라우저나 CLI로 EC2에 접속할 수 있습니다.

### 전제 조건

인스턴스에 SSM Agent가 설치되어 있어야 합니다 (대부분의 최신 AMI에는 기본 설치됨).

### 방법 2-1: AWS 콘솔에서 브라우저 접속

1. **AWS 콘솔 접속**: https://console.aws.amazon.com
2. **EC2 → 인스턴스** 메뉴
3. 인스턴스 선택 (`i-05126306c48bfd8b3`)
4. **"연결"** 버튼 클릭
5. **"Session Manager"** 탭 선택
6. **"연결"** 버튼 클릭

브라우저에서 터미널이 열리면 접속 완료입니다!

### 방법 2-2: AWS CLI로 접속 (SSM 사용)

로컬에 AWS CLI가 설치되어 있다면:

```bash
# AWS CLI 설치 확인
aws --version

# AWS CLI 설정 (아직 안 했다면)
aws configure
# Access Key ID 입력
# Secret Access Key 입력
# Default region name: ap-northeast-2 (서울)
# Default output format: json

# Session Manager로 접속
aws ssm start-session --target i-05126306c48bfd8b3
```

### Session Manager 사용 시 주의사항

- **IAM 역할/권한 필요**: EC2 인스턴스에 SSM 역할이 필요할 수 있음
- **인스턴스 프로필 설정**: 인스턴스에 `AmazonSSMManagedInstanceCore` 정책이 있어야 함

---

## 방법 3: 새 키 페어 생성 후 접속 (마지막 수단)

기존 키를 찾을 수 없고 Session Manager도 작동하지 않으면, 새 키 페어를 생성하고 인스턴스에 연결해야 합니다.

**⚠️ 주의**: 이 방법은 인스턴스를 중지하고 시작해야 할 수 있습니다.

### 3-1: 새 키 페어 생성

1. AWS 콘솔 → EC2 → 키 페어
2. **"키 페어 만들기"** 클릭
3. 이름 입력 (예: `trace-x-new-key`)
4. **"생성"** 클릭
5. `.pem` 파일 자동 다운로드 → 안전한 곳에 저장!

### 3-2: 새 키로 인스턴스 접속

**⚠️ 문제**: 기존 인스턴스는 기존 키 페어로 생성되었으므로, 새 키로는 접속할 수 없습니다.

**해결 방법:**

#### 옵션 A: 인스턴스 중지 후 새 키로 재생성 (데이터 손실 가능)

1. 인스턴스 중지
2. 인스턴스에서 AMI 생성
3. 새 인스턴스 시작 (새 키 페어 선택)

#### 옵션 B: 기존 키 페어 찾기 계속 시도 (권장)

키 페어 파일을 찾는 게 가장 안전합니다.

---

## 방법 4: 기존 키 페어 파일 찾기

### 4-1: 일반적인 저장 위치 확인

```bash
# 다운로드 폴더 확인
ls -la ~/Downloads/*.pem

# 데스크톱 확인
ls -la ~/Desktop/*.pem

# SSH 폴더 확인
ls -la ~/.ssh/*.pem

# AWS 관련 폴더 확인
find ~ -name "*aws*" -type d 2>/dev/null
find ~ -name "*ec2*" -type d 2>/dev/null
```

### 4-2: 파일명 패턴 검색

키 페어 이름을 알았다면:

```bash
# 예: 키 페어 이름이 "trace-x-key"인 경우
find ~ -name "*trace*" -name "*.pem" 2>/dev/null
find ~ -name "*key*" -name "*.pem" 2>/dev/null
find ~ -name "*.pem" 2>/dev/null
```

### 4-3: 팀원에게 물어보기

백엔드 팀이나 인스턴스를 생성한 사람에게 키 페어 파일을 요청하세요.

---

## 권장 해결 순서

1. ✅ **AWS 콘솔에서 Session Manager로 접속** (가장 쉬움)

   - EC2 → 인스턴스 → 연결 → Session Manager

2. ✅ **AWS 콘솔에서 키 페어 이름 확인**

   - 인스턴스 세부 정보에서 키 페어 이름 확인
   - 해당 이름의 `.pem` 파일 찾기

3. ✅ **로컬에서 키 파일 검색**

   - `find ~ -name "*.pem"` 실행
   - 일반적인 저장 위치 확인

4. ✅ **팀원에게 키 페어 요청**

   - 백엔드 팀이나 인스턴스 생성자에게 문의

5. ⚠️ **새 키 페어 생성** (마지막 수단)
   - 인스턴스 재생성 필요할 수 있음

---

## Session Manager 설정 (필요 시)

Session Manager가 작동하지 않으면 IAM 역할 설정이 필요할 수 있습니다.

### EC2 인스턴스에 IAM 역할 연결

1. AWS 콘솔 → EC2 → 인스턴스
2. 인스턴스 선택 → "보안" 탭
3. **"IAM 역할"** 확인
4. 역할이 없으면:
   - IAM → 역할 → 새 역할 생성
   - AWS 서비스 → EC2 선택
   - 정책 추가: `AmazonSSMManagedInstanceCore`
   - 역할 이름: `EC2-SSM-Role`
   - 인스턴스에 역할 연결

---

## 키 페어를 찾았다면

```bash
# 1. 키 파일 권한 설정
chmod 400 ~/Downloads/your-key.pem

# 2. SSH 접속
ssh -i ~/Downloads/your-key.pem ubuntu@3.35.164.184
```

---

## 키 페어를 찾지 못했다면

**Session Manager로 접속한 후**, 배포를 진행하세요:

```bash
# Session Manager로 접속했다면 (브라우저 또는 AWS CLI)

# 통합 레포 클론
cd ~
git clone https://github.com/paran-needless-to-say/integration.git trace-x
cd trace-x

# 배포 가이드 확인
cat QUICK_DEPLOY.md

# 배포 진행
# (QUICK_DEPLOY.md 2단계부터 시작)
```

---

## 도움이 필요하신가요?

- AWS 콘솔 → EC2 → 인스턴스 → 연결 → Session Manager 시도
- 팀원에게 키 페어 파일 요청
- AWS 지원팀 문의 (키 페어 복구는 불가능)
