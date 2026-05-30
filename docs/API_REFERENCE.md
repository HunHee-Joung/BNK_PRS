# 내부 모듈 레퍼런스 (API Reference)

> Presentation Evaluator v1.0 — 개발자용 내부 모듈/Provider/Service 레퍼런스

---

## 📚 목차

1. [데이터 모델 (Models)](#1-데이터-모델-models)
2. [상태 관리 (AppProvider)](#2-상태-관리-appprovider)
3. [저장소 (StorageService)](#3-저장소-storageservice)
4. [유틸리티 (Utils)](#4-유틸리티-utils)
5. [공용 위젯 (Common Widgets)](#5-공용-위젯-common-widgets)
6. [상수 및 enum](#6-상수-및-enum)

---

## 1. 데이터 모델 (Models)

위치: `lib/models/app_models.dart`

### 1.1 EvalSession (설명회)

```dart
class EvalSession {
  String id;                  // UUID
  String title;               // 설명회 제목
  String productName;         // 제품명
  String presenterName;       // 발표자
  String presenterCompany;    // 발표사
  DateTime scheduledAt;       // 일시
  SessionStatus status;       // 상태 (enum)
  String templateId;          // FK → EvalTemplate
  List<String> evaluatorIds;  // FK → Evaluator[]
  bool isLocked;              // 집계 잠금 여부
  DateTime? lockedAt;         // 잠금 시각
  String? lockedBy;           // 잠금 수행자 ID
  String notes;               // 관리자 메모
  DateTime createdAt;
  DateTime updatedAt;
}
```

**주요 메서드**:
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `Map<String, dynamic> toJson()` | Map | 직렬화 |
| `factory EvalSession.fromJson(Map)` | EvalSession | 역직렬화 |
| `EvalSession copyWith({...})` | EvalSession | 불변 복사 |

### 1.2 EvalTemplate (평가 템플릿)

```dart
class EvalTemplate {
  String id;
  String name;                 // 템플릿명
  List<Question> questions;    // 평가 항목
  bool isDefault;              // 기본 템플릿 여부
  DateTime createdAt;
  DateTime updatedAt;

  int get totalScore => questions.fold(0, (sum, q) => sum + q.maxScore);
}
```

### 1.3 Question (평가 항목)

```dart
class Question {
  String id;
  String text;          // 항목명
  int maxScore;         // 배점
  String? description;  // 설명
  int order;            // 표시 순서
}
```

### 1.4 Evaluator (평가자)

```dart
class Evaluator {
  String id;
  String name;
  String department;
  String organization;
  bool isActive;
  DateTime createdAt;
}
```

### 1.5 Evaluation (평가 결과)

```dart
class Evaluation {
  String id;
  String sessionId;                // FK → EvalSession
  String evaluatorId;              // FK → Evaluator
  Map<String, int> scores;         // {questionId: score}
  String? comment;                 // 종합 의견
  EvaluationStatus status;         // draft / submitted
  DateTime? submittedAt;
  DateTime updatedAt;

  int get totalScore => scores.values.fold(0, (a, b) => a + b);
}
```

### 1.6 AuditLog (감사 로그)

```dart
class AuditLog {
  String id;
  DateTime timestamp;
  String actorId;            // 수행자 ID
  String actorName;          // 수행자 이름 (스냅샷)
  AuditAction action;        // enum
  String targetType;         // 예: "EvalSession"
  String? targetId;
  Map<String, dynamic>? details;  // 변경 내용
  String? note;              // 메모 (예: 잠금 사유)
}
```

---

## 2. 상태 관리 (AppProvider)

위치: `lib/providers/app_provider.dart`

### 2.1 클래스 시그니처

```dart
class AppProvider extends ChangeNotifier {
  // 상태
  Admin? currentAdmin;
  List<EvalSession> sessions = [];
  List<EvalTemplate> templates = [];
  List<Evaluator> evaluators = [];
  List<AuditLog> auditLogs = [];

  bool isLoading = false;
  String? error;
}
```

### 2.2 인증

```dart
Future<bool> login(String adminId, String password);
Future<void> logout();
```

**예시**:
```dart
final provider = context.read<AppProvider>();
final ok = await provider.login('admin01', 'pwd123');
if (ok) {
  // 로그인 성공 → MainShell로 이동
}
```

### 2.3 데이터 로드

```dart
Future<void> loadAll();          // 모든 데이터 로드
Future<void> loadSessions();
Future<void> loadTemplates();
Future<void> loadEvaluators();
Future<void> loadAuditLogs();
```

### 2.4 설명회 CRUD

```dart
Future<EvalSession> createSession({
  required String title,
  required String productName,
  required String presenterName,
  required String presenterCompany,
  required DateTime scheduledAt,
  required String templateId,
  required List<String> evaluatorIds,
  String notes = '',
});

Future<void> updateSession(EvalSession session);
Future<void> deleteSession(String sessionId);
Future<void> lockSession(String sessionId, {required String reason});
Future<void> changeSessionStatus(String sessionId, SessionStatus newStatus);
```

### 2.5 템플릿 CRUD

```dart
Future<EvalTemplate> createTemplate({
  required String name,
  required List<Question> questions,
  bool isDefault = false,
});

Future<void> updateTemplate(EvalTemplate template);
Future<void> deleteTemplate(String templateId);
Future<void> setDefaultTemplate(String templateId);
```

### 2.6 평가자 CRUD

```dart
Future<Evaluator> createEvaluator({
  required String name,
  required String department,
  String organization = '',
});

Future<void> updateEvaluator(Evaluator evaluator);
Future<void> deactivateEvaluator(String evaluatorId);
```

### 2.7 평가 입력

```dart
Future<Evaluation> submitEvaluation({
  required String sessionId,
  required String evaluatorId,
  required Map<String, int> scores,
  String? comment,
});

Future<Evaluation> saveDraft({...});
List<Evaluation> getEvaluationsForSession(String sessionId);
```

### 2.8 감사 로그

```dart
// 내부에서 자동 호출 (외부 직접 호출 불필요)
Future<void> _recordAudit(AuditAction action, String targetType, String? targetId, {Map? details, String? note});

// 조회
List<AuditLog> getAuditLogs({
  DateTime? from,
  DateTime? to,
  AuditAction? action,
  String? actorId,
});
```

### 2.9 사용 패턴

#### Consumer (자동 리빌드)
```dart
Consumer<AppProvider>(
  builder: (context, provider, _) {
    return Text('총 ${provider.sessions.length}건');
  },
)
```

#### read (이벤트 핸들러)
```dart
ElevatedButton(
  onPressed: () async {
    final provider = context.read<AppProvider>();
    await provider.deleteSession(sessionId);
  },
  child: Text('삭제'),
)
```

#### watch (build 메서드 내부)
```dart
@override
Widget build(BuildContext context) {
  final sessions = context.watch<AppProvider>().sessions;
  return ListView(...);
}
```

---

## 3. 저장소 (StorageService)

위치: `lib/services/storage_service.dart`

### 3.1 싱글톤 패턴

```dart
class StorageService {
  static final instance = StorageService._();
  StorageService._();

  Future<void> init();  // 앱 시작 시 1회 호출
}
```

### 3.2 Hive 박스 이름

```dart
class _BoxNames {
  static const sessions    = 'sessions';
  static const templates   = 'templates';
  static const evaluators  = 'evaluators';
  static const evaluations = 'evaluations';
  static const auditLogs   = 'audit_logs';
  static const admins      = 'admins';
  static const settings    = 'settings';
}
```

### 3.3 주요 메서드

#### Session
```dart
Future<void> saveSession(EvalSession s);
Future<EvalSession?> getSession(String id);
Future<List<EvalSession>> getAllSessions();
Future<void> deleteSession(String id);
```

#### Template / Evaluator / Evaluation
유사한 패턴: `save`, `get`, `getAll`, `delete`

#### AuditLog (append-only)
```dart
Future<void> appendAuditLog(AuditLog log);   // 추가만 가능
Future<List<AuditLog>> getAllAuditLogs();
// ⚠️ delete 메서드 의도적으로 미제공 (무결성 보장)
```

### 3.4 향후 암호화 적용 예시

```dart
// 권장 (Phase 2)
Future<void> init() async {
  await Hive.initFlutter();

  // 1. 디바이스에서 암호화 키 로드 (Keystore / Keychain)
  final keyBytes = await _loadOrGenerateEncryptionKey();
  final cipher = HiveAesCipher(keyBytes);

  // 2. 박스 열기 (암호화 적용)
  await Hive.openBox<Map>(_BoxNames.sessions, encryptionCipher: cipher);
  // ...
}
```

---

## 4. 유틸리티 (Utils)

### 4.1 AppTheme (`lib/utils/app_theme.dart`)

#### 색상 팔레트
```dart
class AppTheme {
  static const primary       = Color(0xFF1A56DB);
  static const primaryLight  = Color(0xFFEBF5FF);
  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const info          = Color(0xFF3B82F6);

  static const background    = Color(0xFFF9FAFB);
  static const surface       = Color(0xFFFFFFFF);
  static const divider       = Color(0xFFE5E7EB);

  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFF9CA3AF);
}
```

#### 그림자
```dart
static const List<BoxShadow> cardShadow = [...];
static const List<BoxShadow> elevatedShadow = [...];
```

#### ThemeData
```dart
static ThemeData get themeData;
```

### 4.2 AppStyles (텍스트 스타일)

```dart
class AppStyles {
  static const headlineLarge   = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const headlineMedium  = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
  static const headlineSmall   = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  static const bodyLarge       = TextStyle(fontSize: 16);
  static const bodyMedium      = TextStyle(fontSize: 14);
  static const bodySmall       = TextStyle(fontSize: 13, color: AppTheme.textSecondary);

  static const labelLarge      = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const labelMedium     = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  static const caption         = TextStyle(fontSize: 11, color: AppTheme.textHint);
}
```

### 4.3 Formatters (`lib/utils/formatters.dart`)

```dart
class Formatters {
  // 날짜 포맷 (한국어)
  static String dateKr(DateTime dt);         // "2026년 5월 30일"
  static String timeKr(DateTime dt);         // "오후 2:30"
  static String dateTimeKr(DateTime dt);     // "2026년 5월 30일 오후 2:30"
  static String dateTimeShort(DateTime dt);  // "05/30 14:30"

  // 숫자 포맷
  static String score(double value, {int digits = 1});  // "85.5"
  static String percent(double ratio);                  // "85.5%"
  static String currency(num value);                    // "1,234,567원"

  // 상대 시간
  static String relativeTime(DateTime dt);   // "3시간 전"
}
```

---

## 5. 공용 위젯 (Common Widgets)

위치: `lib/widgets/common_widgets.dart`

### 5.1 StatusBadge

```dart
StatusBadge(SessionStatus status);

// 예시
StatusBadge(SessionStatus.ongoing)  // 파란색 "진행 중" 배지
```

### 5.2 EmptyState

```dart
EmptyState({
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? action,
});

// 예시
EmptyState(
  icon: Icons.event_busy,
  title: '설명회가 없습니다',
  subtitle: '상단 + 버튼으로 첫 설명회를 만드세요',
  action: ElevatedButton(onPressed: ..., child: Text('생성')),
)
```

### 5.3 LoadingOverlay

```dart
LoadingOverlay({
  required bool isLoading,
  required Widget child,
  String? message,
});

// 예시
LoadingOverlay(
  isLoading: _isLoading,
  message: '저장 중...',
  child: SingleChildScrollView(child: Form(...)),
)
```

### 5.4 InfoCard

```dart
InfoCard({
  required String label,
  required String value,
  String? sublabel,
  required IconData icon,
  Color color = AppTheme.primary,
  VoidCallback? onTap,
});
```

### 5.5 ScoreGaugeBar

```dart
ScoreGaugeBar({
  required double score,
  required double maxScore,
  Color? color,  // null이면 비율에 따라 자동 색상
});
```

### 5.6 다이얼로그 / 스낵바 헬퍼

```dart
// 확인 다이얼로그
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDestructive = false,
});

// 스낵바
void showSuccess(BuildContext context, String message);
void showError(BuildContext context, String message);
void showInfo(BuildContext context, String message);
```

### 5.7 SectionHeader / PageHeader

```dart
SectionHeader({
  required String title,
  String? subtitle,
  Widget? action,
});

PageHeader({
  required String title,
  String? subtitle,
  List<Widget>? actions,
  Widget? leading,
});
```

---

## 6. 상수 및 enum

### 6.1 SessionStatus

```dart
enum SessionStatus {
  scheduled,  // 진행 예정
  ongoing,    // 진행 중
  closed;     // 종료

  String get label;          // 한글 라벨
  Color get color;           // 표시 색상
  IconData get icon;         // 표시 아이콘
}
```

### 6.2 EvaluationStatus

```dart
enum EvaluationStatus {
  draft,       // 임시 저장
  submitted;   // 최종 제출
}
```

### 6.3 AuditAction

```dart
enum AuditAction {
  // 인증
  login,
  logout,
  loginFailed,

  // 설명회
  sessionCreated,
  sessionUpdated,
  sessionDeleted,
  sessionLocked,
  sessionStarted,
  sessionClosed,

  // 템플릿
  templateCreated,
  templateUpdated,
  templateDeleted,

  // 평가자
  evaluatorCreated,
  evaluatorUpdated,
  evaluatorDeactivated,

  // 평가
  evaluationSubmitted,
  evaluationEdited,

  // 내보내기
  exportCsv,
  exportPdf;

  String get label;       // 한글 라벨
  Color get color;        // 표시 색상
}
```

### 6.4 AdminRole

```dart
enum AdminRole {
  superAdmin,   // 슈퍼 관리자
  admin,        // 일반 관리자
  viewer;       // 조회 전용

  String get label;
  bool get canEdit;
  bool get canLock;
  bool get canManageAdmins;
}
```

---

## 7. 확장 가이드 (Extension)

### 7.1 신규 평가 항목 타입 추가 예시

현재는 0~maxScore 정수 입력만 지원. 향후 척도(Likert) / 선택형 추가 시:

```dart
// 1. Question 모델 확장
enum QuestionType { numeric, likert5, choice }

class Question {
  // ... 기존 필드
  QuestionType type;
  List<String>? choices;  // 선택형용
}

// 2. UI 위젯 분기
Widget _buildScoreInput(Question q) {
  switch (q.type) {
    case QuestionType.numeric: return _NumericInput(q);
    case QuestionType.likert5: return _LikertInput(q);
    case QuestionType.choice:  return _ChoiceInput(q);
  }
}
```

### 7.2 신규 화면 추가 절차

1. `lib/screens/<screen_name>.dart` 생성
2. `MainShell._buildScreen()` 또는 라우팅 추가
3. 필요 시 `AppProvider`에 새 메서드 추가
4. 감사 로그 액션 enum에 신규 항목 추가

### 7.3 백엔드 연동 시 Repository 패턴 도입 예시

```dart
abstract class SessionRepository {
  Future<List<EvalSession>> getAll();
  Future<void> save(EvalSession s);
  // ...
}

class LocalSessionRepository implements SessionRepository { ... }
class RemoteSessionRepository implements SessionRepository { ... }

// AppProvider에서 주입받아 사용
class AppProvider extends ChangeNotifier {
  final SessionRepository sessionRepo;
  AppProvider({required this.sessionRepo});
}
```

---

## 8. 테스트 (참고)

위치: `test/`

```bash
# 전체 테스트
flutter test

# 특정 파일
flutter test test/providers/app_provider_test.dart

# 커버리지
flutter test --coverage
```

### 테스트 구조 권장 사항

```
test/
├── models/
│   ├── eval_session_test.dart
│   ├── eval_template_test.dart
│   └── evaluation_test.dart
├── providers/
│   └── app_provider_test.dart
├── services/
│   └── storage_service_test.dart
└── widgets/
    └── common_widgets_test.dart
```

---

📅 **문서 버전**: v1.0
✍️ **최종 수정**: 2026-05-30
🎯 **대상**: 개발자, 유지보수 담당자
