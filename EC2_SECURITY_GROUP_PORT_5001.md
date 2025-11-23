# EC2 보안 그룹에서 포트 5001 열기

EC2 보안 그룹에서 포트 5001을 열어서 리스크 스코어링 API에 외부에서 접근할 수 있도록 설정하는 방법입니다.

---

## 방법 1: AWS 콘솔에서 확인 및 설정 (GUI)

### 1단계: EC2 인스턴스 찾기

1. **AWS 콘솔 접속**: https://console.aws.amazon.com/ec2/
2. **EC2 대시보드**에서 왼쪽 메뉴에서 **"인스턴스"** 클릭
3. 인스턴스 목록에서 `paran_TRace_X` 또는 해당 인스턴스 찾기

### 2단계: 보안 그룹 확인

1. 인스턴스를 클릭하여 상세 정보 확인
2. 아래쪽 **"보안"** 탭 클릭
3. **"보안 그룹"** 이름을 클릭 (예: `sg-xxxxx`)

### 3단계: 인바운드 규칙 확인

1. 보안 그룹 페이지에서 **"인바운드 규칙"** 탭 클릭
2. 포트 5001이 열려있는지 확인:
   - **포트 범위**: 5001
   - **소스**: `0.0.0.0/0` (모든 IP) 또는 특정 IP

### 4단계: 포트 5001 추가 (없는 경우)

1. **"인바운드 규칙 편집"** 버튼 클릭
2. **"규칙 추가"** 클릭
3. 다음 정보 입력:
   - **유형**: `사용자 지정 TCP`
   - **포트 범위**: `5001`
   - **소스**:
     - 모든 IP 허용: `0.0.0.0/0`
     - 특정 IP만 허용: `내 IP` 또는 IP 주소 입력
   - **설명**: `Risk Scoring API`
4. **"규칙 저장"** 클릭

---

## 방법 2: AWS CLI로 확인 및 설정 (터미널)

### 사전 준비

```bash
# AWS CLI 설치 확인
aws --version

# AWS 자격 증명 설정 (이미 되어있으면 생략)
aws configure
```

### 보안 그룹 확인

```bash
# 1. 인스턴스 ID 찾기 (이름으로 검색)
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=paran_TRace_X" \
  --query "Reservations[*].Instances[*].[InstanceId,SecurityGroups[0].GroupId]" \
  --output table

# 또는 인스턴스 ID를 알고 있으면
aws ec2 describe-instances --instance-ids i-xxxxx \
  --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" \
  --output text
```

### 포트 5001이 열려있는지 확인

```bash
# 보안 그룹 ID를 알고 있는 경우
SECURITY_GROUP_ID="sg-xxxxx"  # 실제 보안 그룹 ID로 변경

aws ec2 describe-security-groups \
  --group-ids $SECURITY_GROUP_ID \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`5001\` || ToPort==\`5001\`]" \
  --output table
```

### 포트 5001 추가

```bash
# 보안 그룹 ID 설정
SECURITY_GROUP_ID="sg-xxxxx"  # 실제 보안 그룹 ID로 변경

# 포트 5001 추가 (모든 IP 허용)
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 5001 \
  --cidr 0.0.0.0/0 \
  --description "Risk Scoring API"

# 또는 특정 IP만 허용
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 5001 \
  --cidr YOUR_IP/32 \
  --description "Risk Scoring API"
```

---

## 방법 3: EC2 인스턴스에서 직접 확인

EC2 서버에 SSH로 접속한 후:

```bash
# 서버에서 포트 5001이 열려있는지 확인
sudo netstat -tlnp | grep 5001

# 또는
sudo ss -tlnp | grep 5001

# 방화벽 확인 (UFW 사용 시)
sudo ufw status | grep 5001

# 방화벽에 포트 5001 추가 (필요한 경우)
sudo ufw allow 5001/tcp
```

---

## 확인 방법

### 외부에서 접근 테스트

```bash
# Health Check
curl http://3.38.112.25:5001/health

# Swagger UI
curl http://3.38.112.25:5001/api-docs
```

**성공 응답 예시:**

```json
{
  "status": "ok",
  "service": "aml-risk-engine"
}
```

### 브라우저에서 확인

1. 브라우저 주소창에 입력: `http://3.38.112.25:5001/health`
2. JSON 응답이 보이면 포트가 열려있는 것입니다
3. Swagger UI: `http://3.38.112.25:5001/api-docs`

---

## 문제 해결

### 연결 거부 (Connection refused)

**원인**: 포트가 열려있지 않거나 서버가 실행 중이 아님

**해결**:

1. 보안 그룹에서 포트 5001 확인
2. EC2 서버에서 `docker-compose ps`로 서비스 확인
3. EC2 서버에서 `curl http://localhost:5001/health` 확인

### 타임아웃 (Timeout)

**원인**: 보안 그룹에서 포트가 차단됨

**해결**:

1. 보안 그룹 인바운드 규칙에 포트 5001 추가
2. 올바른 보안 그룹이 인스턴스에 연결되어 있는지 확인

### Mixed-content 에러

**원인**: HTTPS 페이지에서 HTTP 리소스 로드 시도

**해결**:

- `petstore.swagger.io` 대신 EC2 서버의 Swagger UI 직접 접근
- `http://3.38.112.25:5001/api-docs` 사용

---

## 보안 권장사항

### 프로덕션 환경

- **특정 IP만 허용**: `0.0.0.0/0` 대신 필요한 IP만 허용
- **VPN 또는 SSH 터널 사용**: 외부 노출 최소화
- **HTTPS 설정**: Nginx 리버스 프록시 + SSL 인증서

### 개발/테스트 환경

- `0.0.0.0/0` 사용 가능 (모든 IP 허용)
- 하지만 가능하면 특정 IP만 허용하는 것을 권장

---

## 빠른 확인 스크립트

EC2 서버에 SSH 접속 후:

```bash
# 스크립트 작성
cat > check_port_5001.sh << 'EOF'
#!/bin/bash
echo "=== 포트 5001 확인 ==="
echo ""
echo "1. 서비스 상태:"
docker-compose -f /path/to/docker-compose.prod.yml ps risk-scoring
echo ""
echo "2. 로컬 접근 테스트:"
curl -s http://localhost:5001/health | jq .
echo ""
echo "3. 포트 리스닝 확인:"
sudo netstat -tlnp | grep 5001 || echo "포트 5001이 리스닝 중이 아닙니다"
EOF

chmod +x check_port_5001.sh
./check_port_5001.sh
```

---

## 요약

1. **AWS 콘솔**: EC2 → 인스턴스 → 보안 그룹 → 인바운드 규칙 편집
2. **포트 5001 추가**: TCP, 포트 5001, 소스 `0.0.0.0/0` (또는 특정 IP)
3. **테스트**: `curl http://3.38.112.25:5001/health`
4. **Swagger UI**: `http://3.38.112.25:5001/api-docs`
