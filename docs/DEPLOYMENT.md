# 배포 가이드 (Deployment Guide)

> Presentation Evaluator v1.0 — 금융기관 폐쇄망 환경 배포 가이드

---

## 📚 목차

1. [배포 시나리오](#1-배포-시나리오)
2. [사전 준비](#2-사전-준비)
3. [Web 배포](#3-web-배포)
4. [Android APK 배포](#4-android-apk-배포)
5. [환경별 설정](#5-환경별-설정)
6. [배포 검증](#6-배포-검증)
7. [롤백 절차](#7-롤백-절차)

---

## 1. 배포 시나리오

### 시나리오 A: 웹 기반 사내 호스팅 (권장)
```
[사내 서버 (nginx)] ──HTTPS──► [사용자 브라우저]
   └─ /var/www/presentation-evaluator/
```

**장점**:
- 별도 설치 없이 브라우저로 접근
- 중앙 집중식 업데이트
- 다양한 디바이스(Windows PC, Mac, 태블릿) 지원

**적합 환경**:
- 사내망에 웹 서버 구축 가능한 경우
- 행사장에서 사내 Wi-Fi 사용 가능한 경우

### 시나리오 B: Android APK 사이드로드
```
[사내 MDM] ──배포──► [태블릿 디바이스]
```

**장점**:
- 오프라인 동작 가능
- 행사장 네트워크 의존성 없음

**적합 환경**:
- 외부 행사장 (사내망 접근 불가)
- 단일 디바이스 1:1 평가 시나리오

### 시나리오 C: 데스크탑 배포 (Windows/macOS)
- Flutter Desktop 빌드 활용
- 사내 PC 전용 배포 시 검토

---

## 2. 사전 준비

### 2.1 빌드 환경

| 항목 | 요구사항 |
|------|---------|
| **OS** | Linux (Ubuntu 22.04+) / macOS / Windows |
| **Flutter SDK** | 3.35.4 (고정) |
| **Dart** | 3.9.2 (고정) |
| **Java** | OpenJDK 17.0.2 (Android 빌드용) |
| **Android SDK** | API Level 35 |
| **Node.js** | (선택) 빌드 자동화 스크립트용 |

### 2.2 폐쇄망 빌드 환경 구성

폐쇄망에서 빌드해야 하는 경우, **사전 의존성 미러링**이 필요합니다:

```bash
# 1) 외부망 환경에서 의존성 다운로드
flutter pub get
flutter precache
# .pub-cache 디렉토리 전체를 폐쇄망 빌드 서버로 복사

# 2) 폐쇄망에서 pub mirror 설정 (선택)
export PUB_HOSTED_URL=https://<사내 pub 미러>
export FLUTTER_STORAGE_BASE_URL=https://<사내 flutter 미러>
```

### 2.3 서명 키 준비 (Android)

```bash
# 키스토어 생성 (최초 1회)
keytool -genkey -v -keystore release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias presentation-evaluator
```

**보관 위치**:
- 🔒 키스토어 파일: 정보보호팀 금고 (오프라인)
- 🔒 비밀번호: 별도 비밀관리 시스템 (HashiCorp Vault 등)

`android/key.properties` 파일 생성 (⚠️ git 제외):
```properties
storePassword=<비밀번호>
keyPassword=<비밀번호>
keyAlias=presentation-evaluator
storeFile=../release-key.jks
```

---

## 3. Web 배포

### 3.1 빌드

```bash
cd flutter_app

# 의존성 설치
flutter pub get

# 분석 (warning 0건 권장)
flutter analyze

# 릴리즈 빌드
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --base-href=/presentation-evaluator/
```

**산출물**: `build/web/` 디렉토리 (정적 파일)

### 3.2 nginx 배포 예시

**`/etc/nginx/sites-available/presentation-evaluator`**:
```nginx
server {
    listen 443 ssl http2;
    server_name eval.internal.bank.local;

    # 사내 인증서
    ssl_certificate     /etc/nginx/certs/internal.crt;
    ssl_certificate_key /etc/nginx/certs/internal.key;

    # 보안 헤더
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:;" always;

    location /presentation-evaluator/ {
        alias /var/www/presentation-evaluator/;
        index index.html;
        try_files $uri $uri/ /presentation-evaluator/index.html;

        # Flutter 캐싱 최적화
        location ~ \.(js|css|wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        location = /presentation-evaluator/index.html {
            expires -1;
            add_header Cache-Control "no-store";
        }
    }

    # 접근 로그 (감사용)
    access_log /var/log/nginx/presentation-evaluator-access.log;
    error_log  /var/log/nginx/presentation-evaluator-error.log;
}

server {
    listen 80;
    server_name eval.internal.bank.local;
    return 301 https://$host$request_uri;
}
```

### 3.3 배포 스크립트

**`scripts/deploy-web.sh`**:
```bash
#!/bin/bash
set -e

VERSION=$(cat pubspec.yaml | grep "^version:" | awk '{print $2}')
DEPLOY_DIR=/var/www/presentation-evaluator
BACKUP_DIR=/var/backups/presentation-evaluator/$(date +%Y%m%d_%H%M%S)

echo "🔨 Building Flutter Web v${VERSION}..."
flutter clean
flutter pub get
flutter build web --release --base-href=/presentation-evaluator/

echo "💾 Backing up current deployment..."
sudo mkdir -p "${BACKUP_DIR}"
sudo cp -r "${DEPLOY_DIR}"/* "${BACKUP_DIR}/" 2>/dev/null || true

echo "🚀 Deploying..."
sudo rm -rf "${DEPLOY_DIR}"/*
sudo cp -r build/web/* "${DEPLOY_DIR}/"

echo "🔐 Setting permissions..."
sudo chown -R www-data:www-data "${DEPLOY_DIR}"
sudo chmod -R 755 "${DEPLOY_DIR}"

echo "🔄 Reloading nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deployed v${VERSION} successfully!"
echo "🔗 Backup: ${BACKUP_DIR}"
```

### 3.4 IIS 배포 (Windows Server)

`web.config`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="Flutter SPA" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/index.html" />
        </rule>
      </rules>
    </rewrite>
    <staticContent>
      <mimeMap fileExtension=".wasm" mimeType="application/wasm" />
    </staticContent>
  </system.webServer>
</configuration>
```

---

## 4. Android APK 배포

### 4.1 빌드

```bash
cd flutter_app

# 릴리즈 APK 빌드
flutter build apk --release \
  --split-per-abi \
  --dart-define=ENVIRONMENT=production

# 산출물
# build/app/outputs/flutter-apk/
#   ├── app-armeabi-v7a-release.apk
#   ├── app-arm64-v8a-release.apk    ← 대부분의 최신 디바이스
#   └── app-x86_64-release.apk
```

### 4.2 APK 서명 검증

```bash
# 서명 정보 확인
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# SHA-256 무결성 해시
sha256sum build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

> 💡 **무결성 해시 공유**: 빌드 후 SHA-256 값을 사내 공지에 함께 게시하여
> 사용자가 다운로드 후 검증할 수 있도록 합니다.

### 4.3 MDM 배포

**예시: VMware Workspace ONE / MS Intune**

1. APK 파일 업로드 (`app-arm64-v8a-release.apk`)
2. 대상 디바이스 그룹 지정 (예: "여신심사본부 평가용 태블릿")
3. 배포 정책 설정:
   - 자동 설치 또는 사용자 선택
   - 업데이트 시 자동 재설치
4. 배포 시작

### 4.4 사이드로드 (수동 설치)

```bash
# adb를 통한 설치
adb install -r app-arm64-v8a-release.apk

# 또는 디바이스에 APK 파일 전송 후 직접 설치
# (개발자 옵션 → "출처 불명 앱 설치 허용" 필요)
```

---

## 5. 환경별 설정

### 5.1 환경 변수 (--dart-define)

빌드 시 환경별 설정 주입:

```bash
# 개발
flutter build web --debug \
  --dart-define=ENVIRONMENT=development \
  --dart-define=LOG_LEVEL=debug

# 스테이징
flutter build web --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=LOG_LEVEL=info

# 운영
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=LOG_LEVEL=warn
```

Dart 코드에서 접근:
```dart
const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
const logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'warn');
```

### 5.2 환경별 구분 표시 (선택)

운영/개발 환경 혼동 방지를 위해 비-운영 환경은 상단에 배너 표시:

```dart
if (env != 'production') {
  // AppBar 색상 빨간색, "[STAGING]" 라벨 표시
}
```

---

## 6. 배포 검증

### 6.1 배포 후 체크리스트

#### Web
- [ ] HTTPS 정상 접속 확인
- [ ] 로그인 동작
- [ ] 새 설명회 생성 → 저장 → 조회 (Hive 영속성)
- [ ] 차트 렌더링 (fl_chart)
- [ ] CSV 내보내기 다운로드 확인
- [ ] 한국어 날짜/시간 표시 확인
- [ ] 다른 브라우저 호환성 (Chrome, Edge, Safari)
- [ ] 접근 로그 정상 기록

#### Android
- [ ] 앱 정상 설치
- [ ] 권한 요청 확인 (필요 시)
- [ ] 가로/세로 회전 정상 동작
- [ ] 오프라인 동작 (Wi-Fi 끄고 테스트)
- [ ] 백그라운드 후 복귀 시 데이터 유지
- [ ] APK 서명 확인

### 6.2 성능 검증

```bash
# Lighthouse (Web)
npx lighthouse https://eval.internal.bank.local/presentation-evaluator/ \
  --output html --output-path ./lighthouse-report.html

# 권장 지표
# Performance: 80+
# Accessibility: 90+
# Best Practices: 90+
```

### 6.3 보안 검증

```bash
# SSL Labs 테스트 (외부망 검증용 - 사내 인증서는 직접 검증)
# 권장: A 등급 이상

# 보안 헤더 확인
curl -I https://eval.internal.bank.local/presentation-evaluator/
# 다음 헤더 확인:
# Strict-Transport-Security
# X-Frame-Options
# X-Content-Type-Options
# Content-Security-Policy
```

---

## 7. 롤백 절차

### 7.1 Web 롤백

```bash
# 1. 백업 디렉토리 확인
ls -la /var/backups/presentation-evaluator/

# 2. 이전 버전 복원
sudo rm -rf /var/www/presentation-evaluator/*
sudo cp -r /var/backups/presentation-evaluator/<백업타임스탬프>/* /var/www/presentation-evaluator/
sudo systemctl reload nginx

# 3. 정상 동작 확인
curl -I https://eval.internal.bank.local/presentation-evaluator/
```

### 7.2 Android 롤백

- MDM 콘솔에서 이전 APK 버전 재배포
- 사용자 디바이스에 자동 다운그레이드 푸시

### 7.3 데이터 호환성 확인

> ⚠️ 롤백 전 **데이터 모델 변경 여부**를 반드시 확인하세요.
> 신규 버전에서 Hive 스키마가 변경된 경우, 기존 데이터를 읽지 못할 수 있습니다.

호환성 매트릭스는 [CHANGELOG.md](./CHANGELOG.md) 참조.

---

## 8. 모니터링

### 8.1 로그 수집

| 로그 종류 | 위치 | 보존 기간 |
|----------|------|----------|
| nginx access | `/var/log/nginx/presentation-evaluator-access.log` | 1년 |
| nginx error | `/var/log/nginx/presentation-evaluator-error.log` | 1년 |
| 앱 감사 로그 | Hive (`audit_logs.hive`) | 5년 |

### 8.2 알람 설정 (예시)

| 조건 | 알람 채널 |
|------|----------|
| 5xx 에러 분당 10건 초과 | 운영팀 슬랙 |
| 로그인 실패 시간당 50건 초과 | 정보보호팀 |
| 디스크 사용량 80% 초과 | IT 인프라팀 |

### 8.3 정기 점검 항목

| 주기 | 항목 |
|------|------|
| **일간** | 접속 로그, 에러 카운트 |
| **주간** | 비정상 패턴 분석 |
| **월간** | 사용자 활동 통계, 용량 점검 |
| **분기** | 보안 패치 적용, 의존성 갱신 검토 |

---

## 9. 트러블슈팅

### Q1. "MIME type 'application/wasm' was not provided" 에러 (Web)
**A.** nginx/IIS의 MIME 타입 설정에 `.wasm` 추가 필요. 위 nginx 예시 참조.

### Q2. 새로고침 시 404 에러 (Web)
**A.** SPA Rewrite 규칙 누락. `try_files $uri $uri/ /index.html;` 추가.

### Q3. APK 설치 시 "앱이 설치되지 않았습니다" 오류
**A.** 다음을 확인:
- 디바이스의 "출처 불명 앱 설치" 허용 여부
- 기존에 다른 서명으로 설치된 동일 패키지 있는지 (제거 필요)
- APK 무결성 (SHA-256 재확인)

### Q4. 한글이 깨져 보임
**A.** 빌드 시 폰트 트리쉐이킹이 한국어 글리프를 제거했을 가능성.
다음 옵션으로 재빌드:
```bash
flutter build web --release --no-tree-shake-icons
```

### Q5. Hive 박스 손상
**A.** 다음 절차:
1. 사용자 디바이스의 Hive 박스 파일 백업
2. 앱 데이터 초기화 (Android: 앱 정보 → 저장공간 → 데이터 삭제)
3. 백업 파일을 개발팀에 전달하여 복구 시도

---

## 10. 배포 승인 프로세스 (참고)

### 사내 IT 변경 관리 절차

1. **변경 요청서 작성** — 변경 내용, 영향도, 롤백 계획
2. **개발팀 내부 검토** — 코드 리뷰, 테스트 결과
3. **정보보호팀 검토** — 보안 영향 평가
4. **CAB (Change Advisory Board)** — 운영 환경 변경 승인
5. **배포 일정 공지** — 사용자 사전 공지 (최소 1일 전)
6. **배포 실행** — 변경 윈도우 내 실행
7. **사후 검증** — 24시간 모니터링
8. **종결 보고** — 결과 보고서 작성

---

📅 **문서 버전**: v1.0
✍️ **최종 수정**: 2026-05-30
🎯 **대상**: 운영팀, 인프라팀, 보안담당자
