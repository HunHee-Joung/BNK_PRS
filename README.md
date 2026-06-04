# Presentation Evaluator (제품 설명회 평가·집계 시스템)

> 금융기관 내부용 제품 설명회 평가 및 집계 MVP — Flutter 기반 멀티 플랫폼(Web / Android / Desktop) 애플리케이션

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Internal-red.svg)]()

---

## 📚 문서

| 문서 | 설명 |
|------|------|
| **[README.md](./README.md)** | 프로젝트 개요 (본 문서) |
| **[docs/SECURITY.md](./docs/SECURITY.md)** | 보안 정책 · STRIDE 위협 모델링 · 컴플라이언스 매핑 |
| **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** | 시스템 아키텍처 · ER 다이어그램 · 데이터 흐름 · 배포 토폴로지 |
| **[docs/CHANGELOG.md](./docs/CHANGELOG.md)** | 버전별 변경 이력 (감사 추적용) |
| **[docs/USER_GUIDE.md](./docs/USER_GUIDE.md)** | 관리자 · 평가자 사용 매뉴얼 (FAQ 포함) |

---

## 📚 문서 인덱스

| 문서 | 설명 | 대상 |
|------|------|------|
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | 시스템 아키텍처 명세 (레이어, 데이터 모델, ADR) | 개발자, 아키텍트 |
| **[SECURITY.md](docs/SECURITY.md)** | 보안 설계, 위협 모델링, 컴플라이언스 매핑 | 정보보호팀, 감사 |
| **[USER_GUIDE.md](docs/USER_GUIDE.md)** | 관리자/평가자 사용 매뉴얼, FAQ | 사용자, 운영팀 |
| **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** | 폐쇄망 배포(nginx/IIS/MDM), 롤백 절차 | 운영팀, 인프라팀 |
| **[API_REFERENCE.md](docs/API_REFERENCE.md)** | 내부 모듈/Provider/Service 레퍼런스 | 개발자, 유지보수 |
| **[CHANGELOG.md](docs/CHANGELOG.md)** | 버전별 변경 이력 (Keep a Changelog 형식) | 모두 |

---

## 📌 개요

금융기관에서 외부 벤더의 제품 설명회를 진행할 때, 평가위원들이 **태블릿/PC 환경에서 표준화된 템플릿으로 평가하고 즉시 집계**할 수 있도록 만든 내부 시스템입니다.

- 종이 평가표 → 디지털 평가 전환
- 평가 진행 중 실시간 집계 가능
- 집계 결과 확정(잠금) 및 감사 로그 기록
- 폐쇄망 배포 가능 (로컬 저장소 기반, 외부 통신 불필요)

---

## 🎯 주요 기능

### 관리자 포털
| 모듈 | 설명 |
|------|------|
| **설명회 관리** | 설명회 생성/수정/삭제, 진행 예정 / 진행 중 / 종료 상태별 탭 관리 |
| **평가 템플릿** | 평가 항목·배점·기본 템플릿 관리, 다중 템플릿 운영 |
| **평가자 관리** | 평가자 등록·활성화, 부서/소속별 관리 |
| **감사 로그** | 모든 주요 액션(생성/수정/삭제/잠금)에 대한 감사 추적 |

### 평가자 워크플로우
- QR 코드 / 인증 코드 기반 평가 세션 진입
- 항목별 점수 입력 + 코멘트
- 임시 저장 및 최종 제출
- 제출 후 결과 화면에서 본인 평가 확인

### 결과 집계
- 평가자별 / 항목별 점수 분포
- 평균 / 표준편차 / 최고·최저 제외 옵션
- CSV 내보내기 (감사 제출용)
- 결과 잠금(Lock) 기능 — 잠금 후 수정 불가

---

## 🏗️ 기술 스택

### Core
- **Flutter 3.35.4** / **Dart 3.9.2** (버전 고정)
- **Material Design 3** UI 시스템

### 상태 관리 / 저장소
- `provider 6.1.5+1` — 상태 관리
- `hive 2.2.3` + `hive_flutter 1.1.0` — 로컬 문서 DB
- `shared_preferences 2.5.3` — 사용자 설정 키-값 저장

### UI / 차트 / 유틸
- `fl_chart ^0.68.0` — 결과 시각화
- `data_table_2 ^2.5.12` — 평가 결과 테이블
- `qr_flutter ^4.1.0` — 평가자 접속 QR
- `intl ^0.20.2` + `flutter_localizations` — 한국어 로케일
- `csv ^6.0.0` — 결과 내보내기

---

## 📁 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                      # 앱 엔트리포인트 + 로케일 초기화
│   ├── models/                        # 데이터 모델 (Session, Template, Evaluator, AuditLog)
│   ├── providers/
│   │   └── app_provider.dart          # 전역 상태 관리 (ChangeNotifier)
│   ├── services/
│   │   └── storage_service.dart       # Hive / SharedPreferences 추상화
│   ├── screens/
│   │   ├── login_screen.dart          # 관리자 로그인
│   │   ├── main_shell.dart            # 사이드/바텀 네비게이션 셸
│   │   ├── session_list_screen.dart   # 설명회 목록 + 검색/탭
│   │   ├── session_create_screen.dart # 설명회 생성/수정
│   │   ├── session_detail_screen.dart # 설명회 상세 + 평가 현황
│   │   ├── template_screen.dart       # 평가 템플릿 CRUD
│   │   ├── evaluator_list_screen.dart # 평가자 관리
│   │   ├── evaluator_auth_screen.dart # 평가자 인증/평가 입력
│   │   ├── result_screen.dart         # 결과 집계 + 차트 + CSV
│   │   └── audit_log_screen.dart      # 감사 로그 조회
│   ├── utils/
│   │   ├── app_theme.dart             # 테마/색상/타이포그래피
│   │   └── formatters.dart            # 날짜·숫자 포맷터
│   └── widgets/
│       └── common_widgets.dart        # 공용 컴포넌트 (StatusBadge, EmptyState 등)
├── assets/
│   └── images/
├── android/                           # Android 빌드 설정
├── web/                               # Web 빌드 진입점
├── pubspec.yaml                       # 의존성 정의
└── README.md
```

---

## 🚀 개발 환경 구동

### 사전 요구사항
- Flutter SDK **3.35.4** (다른 버전 사용 시 호환성 보장 안 됨)
- Dart **3.9.2**
- Android Studio 또는 Chrome (웹 미리보기용)

### 설치 & 실행
```bash
# 의존성 설치
flutter pub get

# 코드 분석
flutter analyze

# 웹 개발 모드
flutter run -d chrome

# 웹 릴리즈 빌드
flutter build web --release

# Android APK 빌드
flutter build apk --release
```

### 웹 정적 호스팅 (폐쇄망용)
```bash
# 1) 빌드
flutter build web --release

# 2) 정적 파일 서빙 (nginx / IIS / Apache 등 무관)
cd build/web && python3 -m http.server 5060
```

---

## 🔒 보안 / 컴플라이언스 고려사항

본 시스템은 **금융기관 내부 폐쇄망 환경**을 가정하여 설계되었습니다.

### ✅ 적용된 보안 원칙
| 항목 | 적용 내용 |
|------|----------|
| **외부 통신 차단** | Firebase/REST API 호출 없음, 모든 데이터 로컬 저장 |
| **로컬 저장소** | Hive 기반 — 사용자 디바이스/서버 내 격리 |
| **감사 로그** | 주요 액션 모두 타임스탬프와 함께 기록 → 사후 추적 가능 |
| **데이터 잠금** | 집계 확정 시 Lock 처리, 위·변조 방지 |
| **로케일 데이터 임베드** | `intl` 패키지 내장 → CDN/외부 네트워크 미사용 |

### ⚠️ 운영 전 검토 필요 항목
- [ ] **APK 서명 키(`*.jks`, `key.properties`)** — `.gitignore` 처리 필수 (현재 미포함)
- [ ] **관리자 계정 인증** — 현재 MVP는 로컬 비밀번호 기반 → 향후 SSO / AD 연동 검토
- [ ] **데이터 백업/복원 정책** — Hive box 파일 백업 절차 수립 필요
- [ ] **개인정보 항목 점검** — 평가자 정보(이름/부서) 보관 기간·삭제 정책 정의
- [ ] **금융위 / FSS 가이드라인** — 내부통제 시스템 변경 시 사전 신고 의무 확인

---

## 🗺️ 향후 로드맵

### Phase 2 — 운영 확장
- [ ] AD/LDAP 기반 관리자 SSO 연동
- [ ] 다국어 지원 (영문 평가자 대응)
- [ ] PDF 결과 보고서 자동 생성
- [ ] 평가 진행 중 실시간 동기화 (WebSocket / SSE)

### Phase 3 — AI 도입 (선택)
- [ ] 평가 코멘트 자동 요약 (온프레미스 LLM 연동, vLLM/Ollama 기반)
- [ ] 이상 점수 패턴 탐지 (점수 담합·일관성 부족 감지)
- [ ] 과거 설명회 대비 비교 분석 (RAG: BGE-M3 + Qdrant)

> AI 기능은 **폐쇄망 온프레미스 LLM** 환경에서만 동작하도록 설계 예정 (외부 API 호출 없음)

---

## 📚 문서 (Documentation)

상세 문서는 [`docs/`](./docs/) 디렉토리에서 확인할 수 있습니다.

| 문서 | 내용 |
|------|------|
| [📐 ARCHITECTURE.md](./docs/ARCHITECTURE.md) | 시스템 아키텍처, 데이터 모델 (ER), 계층 구조, 배포 구성도 |
| [🔒 SECURITY.md](./docs/SECURITY.md) | 위협 모델링(STRIDE), 권한 매트릭스, 컴플라이언스 매핑 (전자금융감독규정·개인정보보호법) |
| [📝 CHANGELOG.md](./docs/CHANGELOG.md) | 버전별 변경 이력, Semantic Versioning 가이드 |

> 💡 **금융기관 내부 심의·감사 제출 시 참고**: 위 3개 문서는 시스템 변경 결재 첨부 자료로 활용할 수 있도록 구성되었습니다.

---

## 📝 라이선스 / 이용 안내

본 시스템은 **금융기관 내부용**으로 개발되었으며, 외부 배포 시 별도 검토가 필요합니다.

---

## 🤝 기여 / 문의

- **개발 책임**: IT기획부 AI인프라팀
- **이슈 등록**: GitHub Issues
- **버전**: v1.0.1 (평가자 인증 UX 단순화 — 입장코드 단독 진입)
