# 시스템 아키텍처 (ARCHITECTURE.md)

> Presentation Evaluator — 시스템 아키텍처 명세서
> 최종 업데이트: 2026-05-30 / 작성: IT기획부 AI인프라팀

---

## 📑 목차

1. [아키텍처 개요](#1-아키텍처-개요)
2. [시스템 컨텍스트](#2-시스템-컨텍스트)
3. [논리적 아키텍처](#3-논리적-아키텍처)
4. [컴포넌트 구조](#4-컴포넌트-구조)
5. [데이터 모델](#5-데이터-모델)
6. [데이터 흐름](#6-데이터-흐름)
7. [상태 관리](#7-상태-관리)
8. [네비게이션 구조](#8-네비게이션-구조)
9. [배포 아키텍처](#9-배포-아키텍처)
10. [확장 로드맵](#10-확장-로드맵)

---

## 1. 아키텍처 개요

### 1.1 설계 원칙

| 원칙 | 설명 |
|------|------|
| **폐쇄망 우선** | 외부 네트워크 의존성 0건, 모든 데이터 로컬 처리 |
| **단일 코드베이스** | Flutter로 Web / Android / Desktop 동시 지원 |
| **계층 분리** | UI ↔ Provider ↔ Service ↔ Storage 의 명확한 책임 분리 |
| **상태 단방향 흐름** | Provider 기반 단방향 데이터 흐름 |
| **테스트 용이성** | Service 계층 추상화로 단위 테스트 가능 |
| **감사 가능성** | 모든 주요 액션이 AuditLog로 추적됨 |

### 1.2 기술 선택 근거

| 결정 사항 | 채택 이유 |
|----------|----------|
| **Flutter 3.35.4** | 단일 코드베이스 + 태블릿/PC 동시 지원 + 한글 렌더링 안정성 |
| **Hive (로컬 DB)** | NoSQL, 트랜잭션 지원, 외부 통신 불필요 → 폐쇄망 적합 |
| **Provider (상태관리)** | Flutter 공식 권장, 학습 곡선 낮음, 작은 규모 앱 적합 |
| **Material Design 3** | 표준 UI 시스템, 접근성 기본 지원 |

---

## 2. 시스템 컨텍스트

### 2.1 C4 — System Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          사내 폐쇄망                              │
│                                                                  │
│   ┌──────────────┐         ┌──────────────────┐                 │
│   │  관리자       │ ──────► │                  │                 │
│   │  (운영팀)     │         │  Presentation    │                 │
│   └──────────────┘         │   Evaluator      │                 │
│                            │   (Flutter App)  │                 │
│   ┌──────────────┐         │                  │                 │
│   │  평가위원     │ ──────► │                  │                 │
│   │  (Tablet)    │         │                  │                 │
│   └──────────────┘         └────────┬─────────┘                 │
│                                     │                            │
│                                     ▼                            │
│                            ┌──────────────────┐                 │
│                            │  로컬 Hive 저장소  │                 │
│                            │  (디바이스 내)    │                 │
│                            └──────────────────┘                 │
│                                                                  │
│   ┌──────────────────────────────────────────────┐              │
│   │  (Phase 2) AD/LDAP / SIEM / 감사 시스템      │              │
│   └──────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              ║
                              ║ [방화벽: 외부 통신 차단]
                              ║
                       ┌────────────┐
                       │  외부 인터넷 │ (접근 불가)
                       └────────────┘
```

### 2.2 액터 (Actors)

| 액터 | 역할 | 주요 활동 |
|------|------|----------|
| **시스템 관리자** | IT 담당 | 사용자 관리, 시스템 설정, 감사 로그 조회 |
| **운영 관리자** | 사업부 담당 | 설명회 등록, 템플릿 관리, 결과 집계 |
| **평가위원** | 외부/내부 심사위원 | 설명회 평가 입력, 결과 확인 |

---

## 3. 논리적 아키텍처

### 3.1 계층 구조 (4-Layer)

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                     │
│                  (lib/screens/, widgets/)                │
│                                                         │
│  - 사용자 인터페이스 (Flutter Widgets)                  │
│  - 입력 유효성 검증                                      │
│  - 로컬 UI 상태 (StatefulWidget)                        │
└────────────────────────┬────────────────────────────────┘
                         │ Consumer<AppProvider>
                         ▼
┌─────────────────────────────────────────────────────────┐
│                Application Layer                        │
│                (lib/providers/)                          │
│                                                         │
│  - AppProvider (ChangeNotifier)                         │
│  - 비즈니스 로직 조율                                    │
│  - 상태 변경 알림                                        │
└────────────────────────┬────────────────────────────────┘
                         │ await service.method()
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  Service Layer                          │
│                  (lib/services/)                         │
│                                                         │
│  - StorageService (Hive/SharedPreferences 추상화)       │
│  - 데이터 영속성 책임                                    │
│  - 트랜잭션 관리                                         │
└────────────────────────┬────────────────────────────────┘
                         │ box.put() / box.get()
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Storage Layer                         │
│                                                         │
│  - Hive Box (sessionBox, templateBox, evaluatorBox,    │
│              responseBox, adminBox, auditBox)          │
│  - SharedPreferences (UI 설정, 현재 사용자)             │
└─────────────────────────────────────────────────────────┘
```

### 3.2 의존성 방향

> ⬇️ **상위 계층은 하위 계층만 참조** (역방향 의존 금지)
>
> - Screen → Provider → Service → Storage ✅
> - Storage → Service → Provider → Screen ❌

---

## 4. 컴포넌트 구조

### 4.1 화면(Screen) 컴포넌트 맵

```
LoginScreen
   │ (인증 성공)
   ▼
MainShell  ─────────────────────────────────────────
   │                                                │
   ├──► 탭 1: SessionListScreen                    │
   │       │                                        │
   │       ├──► SessionCreateScreen (신규/수정)    │
   │       │                                        │
   │       └──► SessionDetailScreen                │
   │             │                                  │
   │             ├──► EvaluatorAuthScreen          │
   │             │      └──► (평가 입력 위젯)      │
   │             │                                  │
   │             └──► ResultScreen (집계 결과)     │
   │                                                │
   ├──► 탭 2: TemplateScreen (템플릿 CRUD)         │
   │                                                │
   ├──► 탭 3: EvaluatorListScreen (평가자 관리)   │
   │                                                │
   └──► 탭 4: AuditLogScreen (감사 로그)          │
   ─────────────────────────────────────────────────
```

### 4.2 공용 위젯 (lib/widgets/common_widgets.dart)

| 위젯 | 용도 |
|------|------|
| `StatusBadge` | 설명회 상태(예정/진행/종료) 표시 |
| `SectionHeader` | 화면 섹션 제목 + 선택 액션 버튼 |
| `InfoCard` | 통계/요약 정보 카드 |
| `EmptyState` | 빈 목록 상태 안내 |
| `LoadingOverlay` | 비동기 작업 중 오버레이 |
| `ScoreGaugeBar` | 점수 게이지 시각화 |
| `LabeledDivider` | 라벨이 있는 구분선 |
| `PageHeader` | 페이지 상단 헤더 |
| `showConfirmDialog` | 확인 다이얼로그 헬퍼 |
| `showSuccess/Error/Info` | SnackBar 헬퍼 |

---

## 5. 데이터 모델

### 5.1 ER 다이어그램

```
┌──────────────────┐         ┌──────────────────┐
│    Template      │         │    Evaluator     │
├──────────────────┤         ├──────────────────┤
│ id (PK)          │         │ id (PK)          │
│ name             │         │ name             │
│ description      │         │ department       │
│ isDefault        │         │ organization     │
│ questions[]      │         │ isActive         │
│ totalScore       │         │ createdAt        │
└────────┬─────────┘         └─────────┬────────┘
         │                             │
         │ 1                         M │
         │                             │
         ▼                             ▼
┌────────────────────────────────────────────────┐
│              EvalSession                       │
├────────────────────────────────────────────────┤
│ id (PK)                                        │
│ title                                          │
│ productName                                    │
│ presenterName                                  │
│ presenterCompany                               │
│ scheduledAt                                    │
│ status (scheduled | ongoing | closed)         │
│ templateId (FK → Template)                    │
│ evaluatorIds[] (FK → Evaluator)               │
│ notes                                          │
│ isLocked                                       │
│ createdAt                                      │
└────────┬───────────────────────────────────────┘
         │
         │ 1
         │
         ▼ M
┌────────────────────────────────────────────────┐
│               EvalResponse                     │
├────────────────────────────────────────────────┤
│ id (PK)                                        │
│ sessionId (FK → EvalSession)                  │
│ evaluatorId (FK → Evaluator)                  │
│ scores: Map<questionId, score>                │
│ comment                                        │
│ submittedAt                                    │
│ isSubmitted                                    │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│                AuditLog                        │
├────────────────────────────────────────────────┤
│ id (PK)                                        │
│ timestamp                                      │
│ userId                                         │
│ action (LOGIN, CREATE, UPDATE, DELETE, LOCK)  │
│ targetType (Session, Template, Evaluator)     │
│ targetId                                       │
│ details (JSON)                                 │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│                  Admin                         │
├────────────────────────────────────────────────┤
│ id (PK)                                        │
│ username                                       │
│ passwordHash (SHA-256)                        │
│ name                                           │
│ role (SystemAdmin | OperationAdmin)           │
│ lastLoginAt                                    │
└────────────────────────────────────────────────┘
```

### 5.2 Hive Box 매핑

| Box 이름 | 저장 모델 | 용도 |
|----------|----------|------|
| `sessionBox` | `EvalSession` | 설명회 정보 |
| `templateBox` | `EvalTemplate` | 평가 템플릿 |
| `evaluatorBox` | `Evaluator` | 평가위원 |
| `responseBox` | `EvalResponse` | 평가 응답 |
| `adminBox` | `Admin` | 관리자 계정 |
| `auditBox` | `AuditLog` | 감사 로그 (append-only) |

---

## 6. 데이터 흐름

### 6.1 설명회 생성 흐름

```
[관리자]
   │
   │ 1. "설명회 생성" 버튼 클릭
   ▼
[SessionListScreen]
   │
   │ 2. Navigator.push(SessionCreateScreen)
   ▼
[SessionCreateScreen]
   │
   │ 3. Form 입력 + 평가자 선택 + 템플릿 선택
   │ 4. 저장 버튼 클릭
   ▼
[AppProvider.createSession()]
   │
   │ 5. 비즈니스 로직 (유효성, 중복 검사)
   ▼
[StorageService.saveSession()]
   │
   │ 6. Hive box.put()
   ▼
[sessionBox]
   │
   │ 7. AuditLog 기록
   ▼
[auditBox]
   │
   │ 8. notifyListeners() → UI 갱신
   ▼
[SessionListScreen] (목록 자동 갱신)
```

### 6.2 평가 입력 흐름

```
[평가위원]
   │
   │ 1. QR 코드 스캔 / 인증 코드 입력
   ▼
[EvaluatorAuthScreen]
   │
   │ 2. 토큰 검증
   ▼
[평가 입력 화면]
   │
   │ 3. 항목별 점수 + 코멘트 입력
   │ 4. 임시 저장 (선택) → 최종 제출
   ▼
[AppProvider.submitResponse()]
   │
   │ 5. 유효성 검증 (모든 항목 입력 여부)
   ▼
[StorageService.saveResponse()]
   │
   │ 6. responseBox.put()
   │ 7. AuditLog 기록 (제출 이벤트)
   ▼
[결과 확인 화면]
```

### 6.3 집계 확정 흐름

```
[관리자]
   │
   │ 1. 모든 평가자 제출 완료 확인
   ▼
[SessionDetailScreen — "집계 확정" 버튼]
   │
   │ 2. 확인 다이얼로그
   ▼
[AppProvider.lockSession()]
   │
   │ 3. session.isLocked = true
   │ 4. 최종 점수 계산 및 저장
   │ 5. AuditLog 기록 (LOCK 이벤트, 영구 보관)
   ▼
[ResultScreen]
   │
   │ 6. 결과 표시 + CSV 내보내기 가능
```

---

## 7. 상태 관리

### 7.1 AppProvider 구조

```dart
class AppProvider extends ChangeNotifier {
  // 인증 상태
  Admin? _currentAdmin;
  Admin? get currentAdmin => _currentAdmin;

  // 데이터 컬렉션
  List<EvalSession> _sessions = [];
  List<EvalTemplate> _templates = [];
  List<Evaluator> _evaluators = [];
  List<EvalResponse> _responses = [];
  List<AuditLog> _auditLogs = [];

  // Getters
  List<EvalSession> get sessions => _sessions;
  List<EvalTemplate> get templates => _templates;
  // ... 등

  // 비즈니스 메서드
  Future<void> login(String username, String password);
  Future<void> logout();
  Future<void> createSession({...});
  Future<void> updateSession(EvalSession session);
  Future<void> deleteSession(String id);
  Future<void> lockSession(String id);
  Future<void> submitResponse(EvalResponse response);
  Future<void> loadAll(); // 전체 데이터 재로드
}
```

### 7.2 상태 변경 알림 패턴

```
사용자 액션
   │
   ▼
Provider 메서드 호출 (await)
   │
   ├──► StorageService 호출 (영속성)
   │
   ├──► 내부 상태 갱신 (_sessions = [..._sessions, newSession])
   │
   └──► notifyListeners() ────┐
                              │
                              ▼
                       Consumer<AppProvider> 재빌드
                              │
                              ▼
                       UI 자동 갱신
```

### 7.3 Provider 사용 패턴

| 패턴 | 사용 시점 |
|------|----------|
| `context.read<AppProvider>()` | 메서드 호출만 필요할 때 (재빌드 불필요) |
| `context.watch<AppProvider>()` | 빌드 메서드 내에서 데이터 읽기 |
| `Consumer<AppProvider>` | 위젯 트리 일부만 재빌드 (성능 최적화) |

---

## 8. 네비게이션 구조

### 8.1 Root Navigator + Tab Navigator (2단 구조)

```
┌──────────────────────────────────────────────┐
│  MaterialApp                                  │
│  ├─ navigatorKey: rootNavigatorKey           │
│  ├─ home: LoginScreen                         │
│  │                                             │
│  └─ Root Navigator                            │
│     ├─ LoginScreen                            │
│     │                                          │
│     └─ MainShell ──────────────────────       │
│        ├─ 탭 0: Tab Navigator 0              │
│        │  ├─ SessionListScreen                │
│        │  ├─ SessionCreateScreen              │
│        │  └─ SessionDetailScreen              │
│        │     ├─ EvaluatorAuthScreen           │
│        │     └─ ResultScreen                  │
│        │                                       │
│        ├─ 탭 1: Tab Navigator 1              │
│        │  └─ TemplateScreen                   │
│        │                                       │
│        ├─ 탭 2: Tab Navigator 2              │
│        │  └─ EvaluatorListScreen              │
│        │                                       │
│        └─ 탭 3: Tab Navigator 3              │
│           └─ AuditLogScreen                   │
└──────────────────────────────────────────────┘
```

### 8.2 네비게이션 사용 규칙

| 시나리오 | API |
|----------|-----|
| 탭 내부 화면 이동 (push) | `Navigator.of(context).push(...)` |
| 탭 내부 화면 닫기 (pop) | `Navigator.of(context).pop(...)` |
| 로그아웃 등 전체 화면 교체 | `rootNavigatorKey.currentState!.pushReplacement(...)` |
| 모달 전체화면 (탭 무시) | `Navigator.of(context, rootNavigator: true).push(...)` |

### 8.3 반응형 레이아웃

| 화면 폭 | 레이아웃 |
|---------|----------|
| **≥ 768px** (태블릿/PC) | 좌측 사이드 네비게이션 (Side Rail) |
| **< 768px** (모바일) | 하단 네비게이션 바 (Bottom Navigation) |

---

## 9. 배포 아키텍처

### 9.1 빌드 타깃

| 플랫폼 | 빌드 명령 | 산출물 | 배포 방식 |
|--------|----------|--------|----------|
| **Web** | `flutter build web --release` | `build/web/*` (정적 파일) | 사내 nginx/IIS 호스팅 |
| **Android** | `flutter build apk --release` | `*.apk` | 사내 MDM(Mobile Device Management) 배포 |
| **Android (App Bundle)** | `flutter build appbundle --release` | `*.aab` | (사내 마켓 운영 시) |

### 9.2 사내 폐쇄망 배포 토폴로지 (권장)

```
┌─────────────────────────────────────────────────────┐
│  사내 폐쇄망                                          │
│                                                      │
│  ┌──────────────────┐     ┌──────────────────┐     │
│  │  관리자 PC        │     │  평가위원 태블릿   │     │
│  │  (Web 브라우저)   │     │  (Android APK)   │     │
│  └────────┬─────────┘     └────────┬─────────┘     │
│           │                          │                │
│           ▼                          ▼                │
│  ┌──────────────────────────────────────────┐       │
│  │  사내 정적 호스팅 서버                    │       │
│  │  (nginx / IIS / Apache)                  │       │
│  │  - build/web/ 정적 파일 서빙             │       │
│  │  - HTTPS (사내 인증서)                   │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  ┌──────────────────────────────────────────┐       │
│  │  사내 MDM 서버 (Phase 2)                 │       │
│  │  - APK 자동 배포                          │       │
│  │  - 디바이스 정책 (FDE 강제)              │       │
│  └──────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

### 9.3 운영 환경 분리

| 환경 | 용도 | 데이터 |
|------|------|--------|
| **개발 (DEV)** | 기능 개발, 단위 테스트 | 더미 데이터 |
| **스테이징 (STG)** | UAT, 보안 점검 | 익명화 데이터 |
| **운영 (PRD)** | 실제 운영 | 실제 데이터 (감사 로그 활성화) |

---

## 10. 확장 로드맵

### 10.1 Phase 2 — 운영 강화

```
[현재 아키텍처]              [Phase 2 추가 요소]
                                      │
관리자/평가자                          ▼
       │                  ┌───────────────────────┐
       ├──────────────────│   AD/LDAP SSO        │
       │                  │   (Kerberos/SAML)     │
       ▼                  └───────────────────────┘
[Flutter App]                          │
       │                              │
       │                  ┌───────────────────────┐
       ├──────────────────│   MDM 정책 적용       │
       │                  │   (FDE 강제, 원격 와이프) │
       ▼                  └───────────────────────┘
[Hive 로컬 저장]                       │
       │                  ┌───────────────────────┐
       └──────────────────│   외부 SIEM 전송      │
                          │   (감사 로그 중앙화)   │
                          └───────────────────────┘
```

### 10.2 Phase 3 — AI 기능 도입 (선택)

```
[Flutter App]
     │
     │ HTTPS (사내망 내부 통신만)
     ▼
┌────────────────────────────────────┐
│   On-Premise AI Gateway            │
│   (Dify Workflow)                  │
└────┬───────────────────────────────┘
     │
     ├──► [LLM Serving]
     │    - vLLM / Ollama
     │    - 한국어 모델 (Qwen/Llama 기반)
     │
     ├──► [RAG Pipeline]
     │    - 임베딩: BGE-M3
     │    - 벡터 DB: Qdrant
     │    - 과거 평가 데이터 검색
     │
     └──► [AI 기능]
          ① 평가 코멘트 자동 요약
          ② 이상 점수 패턴 탐지
          ③ 과거 설명회 비교 분석
```

**Phase 3 핵심 원칙**:
- ✅ **모든 AI 추론은 온프레미스**, 외부 API 호출 0건
- ✅ 추론 결과도 사내망 내부에만 보관
- ✅ AI 결과는 **참고 자료**일 뿐, 최종 평가는 사람이 결정
- ⚠️ 금융위 「AI 활용 가이드라인」 준수 (모델 설명가능성, 편향 점검)

---

## 11. 참고 문서

- [README.md](../README.md) — 프로젝트 개요
- [SECURITY.md](./SECURITY.md) — 보안 정책 및 위협 모델링
- [CHANGELOG.md](./CHANGELOG.md) — 버전별 변경 이력
- [Flutter 공식 아키텍처 가이드](https://docs.flutter.dev/data-and-backend/state-mgmt/options)
- 금융위 「AI 활용 가이드라인」 (2024.12)

---

*본 문서는 시스템 변경 시마다 갱신되며, 모든 아키텍처 변경은 변경관리(CR) 절차를 따릅니다.*
