# 변경 이력 (CHANGELOG)

본 프로젝트의 모든 주목할 만한 변경 사항은 본 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)을 따르며,
버전 체계는 [Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다.

> **금융감독 컴플라이언스 안내**: 본 시스템은 사내 운영 시스템으로, 모든 릴리스는
> 내부통제 절차에 따라 변경관리 결재를 거친 후 본 파일에 기록됩니다.

---

## [Unreleased]

### Planned
- 관리자 비밀번호 정책 강화 (8자 이상, 90일 주기 변경)
- 30분 유휴 자동 로그아웃
- Hive Encrypted Box 적용 (저장소 암호화)
- AD/LDAP SSO 연동 (Phase 2)
- 평가 결과 PDF 보고서 자동 생성

---

## [1.0.0] - 2026-05-30

> **MVP 최초 릴리스** — 종이 평가표 디지털 전환 1차 시범 운영용

### Added (신규 기능)
- **설명회 관리**
  - 설명회 생성·수정·삭제 기능
  - 상태별 탭 (진행 예정 / 진행 중 / 종료)
  - 검색 기능 (설명회명·제품명·발표자)
  - 한국어 일시 포맷 표시 (예: `2026년 06월 01일 (월) 14:00`)
- **평가 템플릿**
  - 다중 템플릿 관리, 기본 템플릿 지정
  - 평가 항목·배점·가중치 설정
  - 총점 자동 계산
- **평가자 관리**
  - 평가자 등록·활성화 관리
  - 부서·소속별 정보 관리
  - 평가자 일괄 선택/해제
- **평가 입력**
  - QR 코드 / 인증 코드 기반 평가자 접속
  - 항목별 점수 입력 + 종합 코멘트
  - 본인 제출 결과 조회
- **결과 집계**
  - 평가자별·항목별 점수 분포 시각화 (`fl_chart`)
  - 평균·표준편차 계산
  - CSV 내보내기 (감사 제출용)
  - 결과 잠금(Lock) 기능 → 잠금 후 수정 불가
- **감사 로그**
  - 생성·수정·삭제·잠금·내보내기 액션 자동 기록
  - 타임스탬프·실행자·대상 정보 포함
  - 변경 전후 데이터 (`before` / `after`) 저장
- **인프라**
  - Flutter Web / Android / Desktop 멀티 플랫폼 지원
  - 사이드 네비게이션 (태블릿/PC) + 바텀 네비게이션 (모바일) 반응형 UI
  - 탭별 독립 Navigator 패턴 적용 (Bottom Tab UX 표준)
  - 한국어 로케일 완전 지원 (DatePicker / TimePicker 한글화)
  - Hive 기반 로컬 저장소 (외부 통신 0건 → 폐쇄망 배포 가능)

### Security (보안)
- ❌ Firebase / 외부 API / 외부 CDN 의존성 **전면 제거**
- ❌ 텔레메트리·분석 SDK (Firebase Analytics, Sentry 등) 미포함
- ✅ 모든 폰트·아이콘 앱 번들에 임베드 → 망분리 환경 적합
- ✅ 결과 잠금 후 무결성 보장 (관리자도 수정 불가)
- ✅ 감사 로그 Append-Only 처리

### Technical (기술 스택)
- Flutter 3.35.4 / Dart 3.9.2 (버전 고정)
- `provider 6.1.5+1` — 상태 관리
- `hive 2.2.3` + `hive_flutter 1.1.0` — 로컬 DB
- `intl ^0.20.2` + `flutter_localizations` — 한국어 로케일
- `fl_chart ^0.68.0` — 차트
- `qr_flutter ^4.1.0` — QR 코드
- `csv ^6.0.0` — CSV 내보내기

### Documentation (문서)
- `README.md` — 프로젝트 개요·기능·구동 방법
- `docs/SECURITY.md` — 위협 모델링·보안 설계·컴플라이언스
- `docs/ARCHITECTURE.md` — 시스템 아키텍처·데이터 모델
- `docs/CHANGELOG.md` — 본 파일

---

## [0.2.0] - 2026-05-29 (개발 단계)

### Fixed (버그 수정)
- **🐛 설명회 생성 화면 흰 화면 이슈 해결**
  - 원인: `DateFormat('yyyy년 MM월 dd일 (E) HH:mm', 'ko')` 호출 시
    한국어 로케일 데이터가 초기화되지 않아 `LocaleDataException` 발생
  - 대응:
    - `flutter_localizations` 패키지 추가
    - `main()` 함수에 `await initializeDateFormatting('ko_KR', null)` 추가
    - `MaterialApp`에 `localizationsDelegates` + `supportedLocales` 설정
    - `intl` 버전을 `^0.19.0` → `^0.20.2`로 업그레이드 (Flutter SDK pin 호환)

### Added
- 전역 `rootNavigatorKey` 추가 — 탭 독립 Navigator 환경에서 root push 지원
- `MainShell` 로그아웃 시 root navigator로 LoginScreen 교체

---

## [0.1.0] - 2026-05-28 (개발 단계)

### Added (초기 구현)
- Flutter 프로젝트 스캐폴딩 (`flutter create`)
- 도메인 모델 정의 (`Session`, `Template`, `Evaluator`, `AuditLog`)
- Hive 기반 `StorageService` 구현
- `AppProvider` 단일 ChangeNotifier 패턴
- 기본 화면 골격 작성 (10개 화면)
- Material Design 3 테마 적용 (`AppTheme`)
- 공용 위젯 라이브러리 (`common_widgets.dart`)

---

## 📋 변경 이력 작성 가이드

### 카테고리
- **Added** — 신규 기능 추가
- **Changed** — 기존 기능 변경
- **Deprecated** — 곧 제거될 기능
- **Removed** — 제거된 기능
- **Fixed** — 버그 수정
- **Security** — 보안 관련 변경 (취약점 수정·정책 강화 등)
- **Documentation** — 문서 변경
- **Technical** — 의존성·인프라·내부 구조 변경

### 버전 규칙 (Semantic Versioning)
```
MAJOR.MINOR.PATCH
   │     │      │
   │     │      └─── 버그 수정만 (호환 유지)
   │     └────────── 신규 기능 추가 (하위 호환)
   └──────────────── 호환 불가 변경 (Breaking)
```

**예시**:
- `1.0.0` → `1.0.1` : 단순 버그 수정
- `1.0.1` → `1.1.0` : 새 기능 추가 (예: PDF 내보내기)
- `1.1.0` → `2.0.0` : 데이터 모델 변경, 마이그레이션 필요

### 작성 원칙
1. **사용자 관점에서 작성** — 내부 리팩토링은 `Technical` 카테고리로 분리
2. **변경 사유 명시** — 특히 `Security`, `Breaking Change`는 배경 설명 필수
3. **이슈 번호 링크** — 가능하면 GitHub Issue / 사내 티켓 번호 첨부
4. **금융 규제 영향도 표시** — 전자금융감독규정 영향 시 별도 표시

---

## 🔗 관련 문서
- [README](../README.md) — 프로젝트 개요
- [SECURITY](./SECURITY.md) — 보안 정책 및 위협 모델링
- [ARCHITECTURE](./ARCHITECTURE.md) — 시스템 아키텍처
