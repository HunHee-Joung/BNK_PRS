# 변경 이력 (CHANGELOG.md)

> Presentation Evaluator — 버전별 변경 사항 추적
> 본 문서는 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식과 [SemVer](https://semver.org/lang/ko/) 규칙을 따릅니다.
> 금융권 감사 요구사항에 따라 모든 변경 사항은 영구 보관됩니다.

---

## 📑 변경 분류

| 표기 | 의미 |
|------|------|
| `Added` | 새로운 기능 추가 |
| `Changed` | 기존 기능 변경 |
| `Deprecated` | 곧 제거될 기능 표시 |
| `Removed` | 제거된 기능 |
| `Fixed` | 버그 수정 |
| `Security` | 보안 관련 변경 (취약점 수정 등) |
| `Compliance` | 규제 대응 변경 |

---

## [Unreleased] — 다음 릴리즈 예정

### Planned (Phase 2)
- AD/LDAP SSO 연동
- 관리자 30분 무활동 시 자동 로그아웃
- Hive box 파일 무결성 해시 검증
- PDF 결과 보고서 자동 생성

### Planned (Phase 3)
- 온프레미스 LLM 연동 (vLLM/Ollama)
- 평가 코멘트 자동 요약
- RAG 기반 과거 설명회 비교 분석 (BGE-M3 + Qdrant)

---

## [1.0.1] — 2026-06-04

> 🎨 **평가자 인증 UX 단순화** — 금융권 실무 친화적 워크플로우

### Changed
- **평가자 인증 방식 전면 개편**: 4단계 인증 → **입장코드 단독 진입 (1-input flow)**
  - 기존: 설명회ID(UUID) + 이메일 + 생년월일6자리 + 입장코드(6자리 숫자)
  - 신규: **입장코드(8자리, `XXXX-XXXX` 형식) 1개만 입력**
  - 사유: 평가위원회 위원들(타기업 외부 인사 포함)이 설명회ID UUID를 외우거나 정확히 입력하기 어려웠던 UX 이슈 해결
  - 본인확인 전제: 입장코드 발급 시점에 관리자가 본인확인 완료한 것으로 간주 (1회용 코드 + 만료 시간으로 보안 확보)
- **입장코드 형식 강화**:
  - 6자리 숫자 → **8자리 영문대문자+숫자** (`XXXX-XXXX` 패턴)
  - 혼동 방지 문자 제외 (`0`, `1`, `O`, `I`, `L` 미사용)
  - `Random.secure()` + 10회 중복 검사로 충돌 방지
- **세션 상세 → 초대 탭 UX 개선**:
  - 평가자별 입장코드 카드 탭 시 액션 시트 표시
  - **평가자별 개별 QR 코드** 자동 생성 (`eval://code/XXXX-XXXX`)
  - **입장코드 클립보드 복사** 버튼 추가
  - **초대문구 일괄 복사** 버튼 (평가자명/설명회/입장코드/만료시간 한번에 복사)
  - 사용/미사용 통계 헤더 추가
- **세션 상세 → 개요 탭**: 단일 세션 QR 표시 → 입장코드 발급 안내 카드로 변경

### Added
- `EntryCodeAuthResult` 모델 클래스: 입장코드 인증 결과 캡슐화
- `AppProvider.authenticateByEntryCode(String entryCode)`: 신규 단일 입력 인증 메소드
  - 검증 순서: 코드 존재 → 만료 → 사용 여부 → 설명회 상태 → 평가자 활성화
  - 인증 성공 시 `Invitation.isUsed = true`, `usedAt` 자동 기록
  - 감사 로그(`AuditAction.evaluatorAuth`) 자동 생성
- `StorageService.findInvitationByEntryCode(String)`: 입장코드로 초대 조회
- `StorageService.isEntryCodeTaken(String)`: 입장코드 중복 검사 (충돌 방지)
- `AppProvider._generateUniqueEntryCode()`: 비동기 입장코드 생성기 (대소문자 정규화)
- `EvaluatorAuthScreen.prefilledEntryCode` 파라미터: QR 스캔 시 자동 채움
- 입장코드 입력 시 자동 대문자 변환 (`_UpperCaseTextFormatter`)
- 평가자별 QR 코드에 만료시간 시각화 (`Formatters.dateTime`)

### Deprecated
- `EvaluatorAuthScreen.sessionId` 파라미터: Backward compat용으로만 유지 (향후 제거 예정)
- `AppProvider.authenticateEvaluator()`: 신규 진입은 `authenticateByEntryCode()` 사용 권장
- 6자리 숫자 입장코드 형식: 신규 생성 코드는 모두 8자리 영문+숫자 형식

### Security
- 입장코드 엔트로피 증가: 6자리 숫자 (10^6 = 100만) → 8자리 28글자 풀 (28^8 ≈ 3.8 × 10^11)
- 무작위 대입 공격 난이도 약 **38만배 증가**
- 1회용(`isUsed`) + 만료시간(`expiresAt`) 이중 방어 유지
- 모든 인증 시도(성공/실패) 감사 로그 자동 기록

### Compliance
- 금융위 「전자금융감독규정 시행세칙」 §15 (접근통제) 대응:
  - 1회용 입장코드 + 만료 시간 = 1-Time Password 유사 메커니즘
  - 본인확인은 관리자 발급 시점에 완료 (Out-of-band 인증으로 간주)
- FSS 「IT 안전성 가이드라인」 권고사항 반영:
  - 인증 실패 메시지 표준화 (공격자가 추론 가능한 정보 제한)
  - 감사 로그 자동 기록 (감사 추적성 확보)

### Fixed
- 입장코드 입력 필드의 대소문자 혼용으로 인한 인증 실패 → 자동 대문자 변환으로 해결
- 평가자가 설명회ID(UUID) 입력 시 오타로 인한 진입 실패 → 입력 단계 제거로 원천 차단

### Migration Notes
- **기존 1.0.0 발급 입장코드**: 6자리 숫자 형식은 계속 유효 (조회 시 대문자 정규화 비교)
- **신규 발급**: 1.0.1부터 자동으로 8자리 영문+숫자 형식 사용
- **권장**: 진행 중인 설명회는 종료까지 기존 코드 유지, 신규 설명회부터 새 형식 적용

---

## [1.0.0] — 2026-05-30

> 🎉 **첫 MVP 릴리즈**

### Added
- **설명회 관리 모듈**
  - 설명회 생성/수정/삭제 기능
  - 진행 예정 / 진행 중 / 종료 상태별 탭 관리
  - 검색 기능 (제목, 제품명, 발표자 기준)
- **평가 템플릿 모듈**
  - 다중 템플릿 운영 지원
  - 평가 항목별 배점 설정
  - 기본 템플릿 지정 기능
- **평가자 관리 모듈**
  - 평가자 등록/수정/활성화
  - 부서·소속 정보 관리
- **평가자 인증 워크플로우**
  - QR 코드 기반 세션 진입
  - 인증 코드 입력 방식 지원
  - 일회성 토큰 발급/검증
- **평가 입력 화면**
  - 항목별 점수 입력 + 코멘트
  - 임시 저장 및 최종 제출
  - 입력 유효성 검증
- **결과 집계 모듈**
  - 평가자별 / 항목별 점수 분포
  - 평균 / 표준편차 계산
  - 최고·최저 제외 옵션
  - CSV 내보내기
  - 집계 결과 잠금(Lock) 기능
- **감사 로그 모듈**
  - 주요 액션 자동 기록 (생성/수정/삭제/잠금)
  - 타임스탬프 + 사용자 ID + 액션 상세 기록
  - 영구 보관 (삭제 불가)
- **반응형 레이아웃**
  - 태블릿/PC: 좌측 사이드 네비게이션
  - 모바일: 하단 네비게이션 바
- **한국어 로케일 지원**
  - `flutter_localizations` + `intl 0.20.2` 적용
  - DatePicker / TimePicker 한글화
  - 한글 날짜 포맷 (예: `2026년 06월 01일 (월) 14:00`)

### Security
- 외부 네트워크 통신 차단 (Firebase/REST API 미사용)
- 모든 데이터 로컬 Hive 저장소에 저장
- 관리자 비밀번호 SHA-256 해시 처리
- 집계 결과 잠금(Lock) 후 변경 불가
- 감사 로그 Append-Only 정책

### Compliance
- 개인정보 최소 수집 원칙 적용 (이름·부서·소속만 수집)
- 주민등록번호 / 연락처 / 위치정보 미수집
- 감사 로그 보관 기간 5년 정책 수립 (금융권 기준)

### Technical
- **개발 환경**: Flutter 3.35.4 / Dart 3.9.2 (버전 고정)
- **상태 관리**: Provider 6.1.5+1
- **로컬 DB**: Hive 2.2.3 + hive_flutter 1.1.0
- **UI 라이브러리**: Material Design 3
- **차트**: fl_chart 0.68.0
- **테이블**: data_table_2 2.5.12
- **QR 코드**: qr_flutter 4.1.0
- **국제화**: intl 0.20.2 + flutter_localizations (Flutter SDK)
- **CSV 처리**: csv 6.0.0

### Documentation
- `README.md` — 프로젝트 개요 (한글)
- `docs/SECURITY.md` — 보안 정책 및 위협 모델링 (STRIDE 분석)
- `docs/ARCHITECTURE.md` — 시스템 아키텍처 (C4 모델, ER 다이어그램)
- `docs/CHANGELOG.md` — 변경 이력 (본 문서)

---

## [0.9.0] — 2026-05-29 (내부 베타)

### Added
- 핵심 화면 프로토타입 (LoginScreen, MainShell, SessionListScreen)
- Hive 기반 로컬 저장소 초기 구현
- Provider 상태 관리 도입

### Fixed
- 한국어 로케일 초기화 누락으로 인한 설명회 생성 화면 빈 화면 이슈
  - `main.dart` 에 `initializeDateFormatting('ko_KR', null)` 추가
  - `MaterialApp` 에 `localizationsDelegates` 및 `supportedLocales` 추가
  - 관련 의존성: `flutter_localizations` 추가, `intl` 0.19.0 → 0.20.2 업그레이드

### Changed
- `intl` 패키지 버전 0.19.0 → 0.20.2 (flutter_localizations 호환성)

---

## [0.1.0] — 2026-05-15 (초기 설계)

### Added
- Flutter 프로젝트 초기 구조 생성 (`flutter create`)
- 기본 디렉토리 구조 정의:
  - `lib/models/` — 데이터 모델
  - `lib/providers/` — 상태 관리
  - `lib/services/` — 비즈니스 로직
  - `lib/screens/` — 화면
  - `lib/widgets/` — 공용 컴포넌트
  - `lib/utils/` — 유틸리티
- `pubspec.yaml` 의존성 정의
- `.gitignore` 설정 (Flutter 표준 + 빌드 산출물 제외)

---

## 📝 변경 기록 작성 규칙 (개발자 가이드)

### 커밋 메시지 ↔ CHANGELOG 매핑

| Conventional Commits | CHANGELOG 카테고리 |
|----------------------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `docs:` | Documentation |
| `style:`, `chore:` | (CHANGELOG 미기재) |
| `security:` | Security |

### 릴리즈 작성 절차

1. 모든 변경 사항을 `[Unreleased]` 섹션에 누적 기록
2. 릴리즈 시점에 `[Unreleased]` → `[버전번호] - YYYY-MM-DD` 로 이동
3. 보안 관련 변경은 **반드시** `Security` 카테고리에 별도 명시
4. 금융위 신고 대상 변경은 `Compliance` 카테고리로 분리
5. 변경관리(CR) 번호가 있을 경우 항목 끝에 `[CR-2026-001]` 형식으로 부기

### 보안/컴플라이언스 변경 특별 규칙

> 본 시스템은 금융기관 내부 시스템이므로, 다음 변경은 별도 절차가 필요합니다:

- 🔴 **Security 변경**: 사내 보안팀 사전 검토 필수, CVE 번호 명시 (해당 시)
- 🔴 **Compliance 변경**: 컴플라이언스 부서 사전 협의, 관련 규정 명시
- 🟠 **내부통제 시스템 변경**: 금융위 사전 신고 의무 여부 검토 후 진행

---

## 🔗 관련 문서

- [README.md](../README.md) — 프로젝트 개요
- [SECURITY.md](./SECURITY.md) — 보안 정책
- [ARCHITECTURE.md](./ARCHITECTURE.md) — 시스템 아키텍처

---

*본 문서는 감사 추적을 위해 영구 보관되며, 임의 삭제·수정이 금지됩니다.*
*변경 사항 누락 발견 시 즉시 IT기획부 AI인프라팀에 통보하시기 바랍니다.*
