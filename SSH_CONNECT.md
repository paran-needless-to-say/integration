# EC2 SSH 접속 가이드 (빠른 참조)

우분투 인스턴스에 SSH로 접속하는 방법입니다.

---

## 준비된 키 파일

- **키 파일 경로**: `/Users/yelim/Desktop/paran_final/Paran_Trace-X.pem`
- **키 파일 이름**: `Paran_Trace-X.pem`
- **인스턴스 타입**: Ubuntu

---

## 1단계: 키 파일 권한 설정

✅ **이미 완료되었습니다!** (키 파일 권한이 400으로 설정됨)

만약 권한을 다시 설정해야 한다면:

```bash
cd /Users/yelim/Desktop/paran_final
chmod 400 Paran_Trace-X.pem
```

---

## 2단계: EC2 인스턴스 IP 주소 확인

### AWS 콘솔에서 확인

1. **AWS 콘솔 접속**: https://console.aws.amazon.com
2. **EC2 → 인스턴스** 메뉴
3. 인스턴스 선택 (예: `Trace-X` 또는 `i-xxxxx`)
4. 하단 세부 정보에서 **"퍼블릭 IPv4 주소"** 확인
   - 예: `3.35.164.184`
   - 또는 `54.123.45.67`

### IP 주소 예시

```
3.35.164.184
```

이 IP 주소를 복사해두세요!

---

## 3단계: SSH 접속

### 기본 명령어 형식

```bash
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@your-server-ip
```

### 실제 예시 (IP 주소를 본인의 것으로 바꾸세요)

```bash
# 예시 1: IP가 3.35.164.184인 경우
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@3.35.164.184

# 예시 2: IP가 54.123.45.67인 경우
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@54.123.45.67
```

### 접속 전에 확인

터미널에서 다음 명령어를 실행하면 키 파일이 준비되어 있는지 확인할 수 있습니다:

```bash
# 키 파일 확인
ls -l /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem

# 출력 예시:
# -r-------- 1 yelim staff 1674 Nov 23 00:09 Paran_Trace-X.pem
```

---

## 4단계: 접속 성공 확인

접속이 성공하면 다음과 같이 표시됩니다:

```
The authenticity of host '3.35.164.184 (3.35.164.184)' can't be established.
ED25519 key fingerprint is SHA256:xxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes

Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1048-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

...

ubuntu@ip-172-31-xx-xx:~$
```

**`ubuntu@ip-172-31-xx-xx:~$`** 프롬프트가 보이면 접속 성공입니다!

---

## 문제 해결

### 1. "Permission denied (publickey)" 에러

**원인**: 키 파일 권한이 잘못되었거나 경로가 틀림

**해결**:
```bash
# 키 파일 권한 다시 설정
chmod 400 /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem

# 경로 확인 (절대 경로 사용 권장)
ls -l /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem
```

### 2. "Connection timed out" 에러

**원인**: 보안 그룹에서 SSH(22) 포트가 열려있지 않음

**해결**:
1. AWS 콘솔 → EC2 → 인스턴스
2. 인스턴스 선택 → "보안" 탭
3. 보안 그룹 클릭 → "인바운드 규칙" 편집
4. 규칙 추가:
   - 유형: `SSH`
   - 포트: `22`
   - 소스: `내 IP` 또는 `0.0.0.0/0` (테스트 환경)
5. 규칙 저장

### 3. "Host key verification failed" 에러

**원인**: 이전 접속 기록과 호스트 키가 다름

**해결**:
```bash
# ~/.ssh/known_hosts에서 해당 IP 제거
ssh-keygen -R 3.35.164.184  # IP 주소를 본인의 것으로 변경

# 다시 접속 시도
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@3.35.164.184
```

### 4. "WARNING: UNPROTECTED PRIVATE KEY FILE!" 경고

**원인**: 키 파일 권한이 너무 열려있음 (400이어야 함)

**해결**:
```bash
chmod 400 /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem
```

---

## 접속 후 첫 실행할 명령어

접속이 성공했다면 다음 명령어를 실행하세요:

```bash
# 시스템 업데이트
sudo apt-get update

# 현재 디렉토리 확인
pwd
# 출력: /home/ubuntu

# 작업 디렉토리로 이동
cd ~
```

---

## 다음 단계

SSH 접속이 완료되었다면:
- ➡️ [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)의 **2단계**부터 배포를 진행하세요!

---

## 빠른 참조 명령어

```bash
# 키 파일 경로로 이동 (선택사항)
cd /Users/yelim/Desktop/paran_final

# SSH 접속 (IP 주소를 본인의 것으로 변경)
ssh -i Paran_Trace-X.pem ubuntu@your-server-ip

# 또는 절대 경로 사용
ssh -i /Users/yelim/Desktop/paran_final/Paran_Trace-X.pem ubuntu@your-server-ip
```

---

**이제 AWS 콘솔에서 IP 주소를 확인하고 SSH 접속을 시도하세요!** 🚀

