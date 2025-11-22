# EC2에서 디렉토리가 비어있는 문제 해결 (전체 컴포넌트)

## 문제 상황

EC2 서버에서 `git clone` 후 `risk-scoring`, `frontend`, `backend` 디렉토리가 비어있습니다.

## 원인

통합 레포(`integration`)의 각 컴포넌트 디렉토리(`risk-scoring`, `frontend`, `backend`) 안에 `.git` 폴더가 있어서, Git이 이들을 중첩 저장소(서브모듈처럼)로 인식합니다. 그래서 통합 레포에는 디렉토리만 있고 내부 파일들이 커밋되지 않습니다.

## 빠른 해결 방법: 자동 설정 스크립트 사용 (권장)

EC2 서버에서 다음 명령어를 실행하세요:

```bash
# 현재 trace-x 디렉토리에 있는지 확인
cd ~/trace-x

# 설정 스크립트 실행 권한 부여
chmod +x scripts/setup-subdirectories.sh

# 자동 설정 실행 (risk-scoring, frontend, backend 모두 설정)
./scripts/setup-subdirectories.sh
```

이 스크립트는:

- `risk-scoring`을 `aml-risk-engine2` 레포에서 클론
- `frontend`를 `frontend` 레포에서 클론
- `backend`를 `100end` 레포에서 클론
- 각 Dockerfile 존재 여부 확인

### 방법 2: 수동으로 각각 클론

EC2 서버에서 다음 명령어를 하나씩 실행하세요:

```bash
# 현재 trace-x 디렉토리에 있는지 확인
cd ~/trace-x

# 1. risk-scoring 설정
rm -rf risk-scoring
git clone https://github.com/paran-needless-to-say/aml-risk-engine2.git risk-scoring

# 2. frontend 설정
rm -rf frontend
git clone https://github.com/paran-needless-to-say/frontend.git frontend

# 3. backend 설정
rm -rf backend
git clone https://github.com/paran-needless-to-say/100end.git backend

# 확인
ls -la risk-scoring/Dockerfile
ls -la frontend/Dockerfile.prod
ls -la backend/Dockerfile
```

### 방법 3: 원격 레포 확인 및 수정 (나중에)

원격 레포에 `risk-scoring` 파일들이 실제로 포함되어 있는지 확인:

```bash
# 로컬에서 원격 레포 확인
cd ~/Desktop/paran_final/trace-x

# 원격 레포에서 risk-scoring 파일 확인
git ls-tree -r HEAD --name-only | grep risk-scoring

# 또는 GitHub에서 직접 확인
# https://github.com/paran-needless-to-say/integration/tree/main/risk-scoring
```

**만약 원격 레포에 `risk-scoring` 파일들이 없다면:**

1. 로컬에서 `risk-scoring` 파일들을 커밋하고 푸시해야 합니다.
2. 또는 방법 1을 사용하여 별도로 클론합니다.

### 방법 3: 로컬에서 수정 후 푸시 (선택사항)

로컬에서 `risk-scoring` 파일들이 통합 레포에 포함되도록 수정:

```bash
# 로컬 trace-x 디렉토리에서
cd ~/Desktop/paran_final/trace-x

# risk-scoring이 서브모듈처럼 동작하는 경우, .git 제거
cd risk-scoring
rm -rf .git
cd ..

# 모든 파일 추가
git add risk-scoring/

# 커밋 및 푸시
git commit -m "Add risk-scoring files to integration repo"
git push origin main
```

## 권장 해결 순서

1. **방법 1 실행** (가장 빠름)

   - EC2 서버에서 `git clone https://github.com/paran-needless-to-say/aml-risk-engine2.git risk-scoring`

2. **배포 재시도**

   ```bash
   ./scripts/deploy.sh
   ```

3. **나중에 방법 3 실행** (선택사항)
   - 로컬에서 통합 레포에 포함하도록 수정
   - 원격 레포에 푸시

---

## 확인 방법

```bash
# Dockerfile 확인
ls -la risk-scoring/Dockerfile

# 주요 파일 확인
ls -la risk-scoring/run_server.py
ls -la risk-scoring/requirements.txt
ls -la risk-scoring/api/app.py
```

모든 파일이 있다면 배포를 진행하세요!
