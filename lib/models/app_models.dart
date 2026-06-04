// ============================================================
// 금융기관용 제품 설명회 평가·집계 시스템 - 데이터 모델
// ============================================================


// ── 사용자 역할 ──────────────────────────────────────────────
enum UserRole { admin, superAdmin, auditor }

// ── 설명회 상태 ──────────────────────────────────────────────
enum SessionStatus { scheduled, ongoing, closed }

// ── 평가 문항 타입 ────────────────────────────────────────────
enum QuestionType { rating10, directInput }

// ── 감사로그 액션 ─────────────────────────────────────────────
enum AuditAction {
  login,
  logout,
  sessionCreate,
  sessionEdit,
  sessionClose,
  evaluatorRegister,
  evaluatorAuth,
  submissionCreate,
  submissionReopen,
  resultView,
  resultDownload,
  templateCreate,
  templateEdit,
}

// ══════════════════════════════════════════════════════════════
// 관리자 계정
// ══════════════════════════════════════════════════════════════
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash; // SHA-256 해시
  final UserRole role;
  final String department;
  final DateTime createdAt;
  DateTime? lastLoginAt;
  bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.department,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.index,
        'department': department,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'isActive': isActive,
      };

  factory AdminUser.fromMap(Map<String, dynamic> m) => AdminUser(
        id: m['id'],
        name: m['name'],
        email: m['email'],
        passwordHash: m['passwordHash'],
        role: UserRole.values[m['role']],
        department: m['department'],
        createdAt: DateTime.parse(m['createdAt']),
        lastLoginAt: m['lastLoginAt'] != null ? DateTime.parse(m['lastLoginAt']) : null,
        isActive: m['isActive'] ?? true,
      );
}

// ══════════════════════════════════════════════════════════════
// 평가 문항
// ══════════════════════════════════════════════════════════════
class Question {
  final String id;
  String title;
  String description;
  int maxScore;
  bool isRequired;
  bool hasComment;
  QuestionType type;
  int orderIndex;

  Question({
    required this.id,
    required this.title,
    this.description = '',
    required this.maxScore,
    this.isRequired = true,
    this.hasComment = false,
    this.type = QuestionType.rating10,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'maxScore': maxScore,
        'isRequired': isRequired,
        'hasComment': hasComment,
        'type': type.index,
        'orderIndex': orderIndex,
      };

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'],
        title: m['title'],
        description: m['description'] ?? '',
        maxScore: m['maxScore'],
        isRequired: m['isRequired'] ?? true,
        hasComment: m['hasComment'] ?? false,
        type: QuestionType.values[m['type'] ?? 0],
        orderIndex: m['orderIndex'],
      );

  Question copyWith({
    String? title,
    String? description,
    int? maxScore,
    bool? isRequired,
    bool? hasComment,
    QuestionType? type,
    int? orderIndex,
  }) =>
      Question(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        maxScore: maxScore ?? this.maxScore,
        isRequired: isRequired ?? this.isRequired,
        hasComment: hasComment ?? this.hasComment,
        type: type ?? this.type,
        orderIndex: orderIndex ?? this.orderIndex,
      );
}

// ══════════════════════════════════════════════════════════════
// 평가 템플릿
// ══════════════════════════════════════════════════════════════
class EvalTemplate {
  final String id;
  String name;
  String description;
  List<Question> questions;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isDefault;

  EvalTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  int get totalScore => questions.fold(0, (sum, q) => sum + q.maxScore);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'questions': questions.map((q) => q.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory EvalTemplate.fromMap(Map<String, dynamic> m) => EvalTemplate(
        id: m['id'],
        name: m['name'],
        description: m['description'] ?? '',
        questions: (m['questions'] as List)
            .map((q) => Question.fromMap(Map<String, dynamic>.from(q)))
            .toList(),
        createdAt: DateTime.parse(m['createdAt']),
        updatedAt: DateTime.parse(m['updatedAt']),
        isDefault: m['isDefault'] ?? false,
      );
}

// ══════════════════════════════════════════════════════════════
// 평가자
// ══════════════════════════════════════════════════════════════
class Evaluator {
  final String id;
  String name;
  String email;
  String birthDate6; // YYMMDD (암호화 저장 권장)
  String department;
  String organization;
  final DateTime registeredAt;
  bool isActive;

  Evaluator({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate6,
    required this.department,
    required this.organization,
    required this.registeredAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'birthDate6': birthDate6,
        'department': department,
        'organization': organization,
        'registeredAt': registeredAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Evaluator.fromMap(Map<String, dynamic> m) => Evaluator(
        id: m['id'],
        name: m['name'],
        email: m['email'],
        birthDate6: m['birthDate6'],
        department: m['department'] ?? '',
        organization: m['organization'] ?? '',
        registeredAt: DateTime.parse(m['registeredAt']),
        isActive: m['isActive'] ?? true,
      );
}

// ══════════════════════════════════════════════════════════════
// 초대 토큰 (평가자별 일회용)
// ══════════════════════════════════════════════════════════════
class Invitation {
  final String id;
  final String sessionId;
  final String evaluatorId;
  final String token; // UUID 기반 일회용 토큰
  final String entryCode; // 6자리 입장코드
  bool isUsed;
  DateTime? usedAt;
  final DateTime expiresAt;
  DateTime? sessionAt; // 실제 접속 시각

  Invitation({
    required this.id,
    required this.sessionId,
    required this.evaluatorId,
    required this.token,
    required this.entryCode,
    this.isUsed = false,
    this.usedAt,
    required this.expiresAt,
    this.sessionAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'evaluatorId': evaluatorId,
        'token': token,
        'entryCode': entryCode,
        'isUsed': isUsed,
        'usedAt': usedAt?.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'sessionAt': sessionAt?.toIso8601String(),
      };

  factory Invitation.fromMap(Map<String, dynamic> m) => Invitation(
        id: m['id'],
        sessionId: m['sessionId'],
        evaluatorId: m['evaluatorId'],
        token: m['token'],
        entryCode: m['entryCode'],
        isUsed: m['isUsed'] ?? false,
        usedAt: m['usedAt'] != null ? DateTime.parse(m['usedAt']) : null,
        expiresAt: DateTime.parse(m['expiresAt']),
        sessionAt: m['sessionAt'] != null ? DateTime.parse(m['sessionAt']) : null,
      );
}

// ══════════════════════════════════════════════════════════════
// 입장코드 인증 결과
// ══════════════════════════════════════════════════════════════
class EntryCodeAuthResult {
  final bool ok;
  final String? errorMessage;
  final EvalSession? session;
  final Evaluator? evaluator;

  const EntryCodeAuthResult._({
    required this.ok,
    this.errorMessage,
    this.session,
    this.evaluator,
  });

  factory EntryCodeAuthResult.success({
    required EvalSession session,
    required Evaluator evaluator,
  }) =>
      EntryCodeAuthResult._(ok: true, session: session, evaluator: evaluator);

  factory EntryCodeAuthResult.fail(String message) =>
      EntryCodeAuthResult._(ok: false, errorMessage: message);
}

// ══════════════════════════════════════════════════════════════
// 설명회 (Session)
// ══════════════════════════════════════════════════════════════
class EvalSession {
  final String id;
  String title;
  String productName;
  String presenterName;
  String presenterCompany;
  DateTime scheduledAt;
  SessionStatus status;
  String templateId;
  List<String> evaluatorIds;
  final String createdBy;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? closedAt;
  bool isLocked; // 최종 집계 확정 후 잠금
  String notes;

  EvalSession({
    required this.id,
    required this.title,
    required this.productName,
    required this.presenterName,
    required this.presenterCompany,
    required this.scheduledAt,
    this.status = SessionStatus.scheduled,
    required this.templateId,
    required this.evaluatorIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.isLocked = false,
    this.notes = '',
  });

  String get statusLabel {
    switch (status) {
      case SessionStatus.scheduled:
        return '진행 예정';
      case SessionStatus.ongoing:
        return '진행 중';
      case SessionStatus.closed:
        return '종료';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'productName': productName,
        'presenterName': presenterName,
        'presenterCompany': presenterCompany,
        'scheduledAt': scheduledAt.toIso8601String(),
        'status': status.index,
        'templateId': templateId,
        'evaluatorIds': evaluatorIds,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'isLocked': isLocked,
        'notes': notes,
      };

  factory EvalSession.fromMap(Map<String, dynamic> m) => EvalSession(
        id: m['id'],
        title: m['title'],
        productName: m['productName'],
        presenterName: m['presenterName'],
        presenterCompany: m['presenterCompany'] ?? '',
        scheduledAt: DateTime.parse(m['scheduledAt']),
        status: SessionStatus.values[m['status']],
        templateId: m['templateId'],
        evaluatorIds: List<String>.from(m['evaluatorIds'] ?? []),
        createdBy: m['createdBy'],
        createdAt: DateTime.parse(m['createdAt']),
        updatedAt: DateTime.parse(m['updatedAt']),
        closedAt: m['closedAt'] != null ? DateTime.parse(m['closedAt']) : null,
        isLocked: m['isLocked'] ?? false,
        notes: m['notes'] ?? '',
      );
}

// ══════════════════════════════════════════════════════════════
// 제출 (Submission) - 평가 헤더
// ══════════════════════════════════════════════════════════════
class Submission {
  final String id;
  final String sessionId;
  final String evaluatorId;
  bool isSubmitted;
  DateTime? submittedAt;
  final DateTime startedAt;
  DateTime? lastModifiedAt;
  bool isReopened;
  String reopenReason;
  int totalScore;

  Submission({
    required this.id,
    required this.sessionId,
    required this.evaluatorId,
    this.isSubmitted = false,
    this.submittedAt,
    required this.startedAt,
    this.lastModifiedAt,
    this.isReopened = false,
    this.reopenReason = '',
    this.totalScore = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'evaluatorId': evaluatorId,
        'isSubmitted': isSubmitted,
        'submittedAt': submittedAt?.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'isReopened': isReopened,
        'reopenReason': reopenReason,
        'totalScore': totalScore,
      };

  factory Submission.fromMap(Map<String, dynamic> m) => Submission(
        id: m['id'],
        sessionId: m['sessionId'],
        evaluatorId: m['evaluatorId'],
        isSubmitted: m['isSubmitted'] ?? false,
        submittedAt: m['submittedAt'] != null ? DateTime.parse(m['submittedAt']) : null,
        startedAt: DateTime.parse(m['startedAt']),
        lastModifiedAt: m['lastModifiedAt'] != null ? DateTime.parse(m['lastModifiedAt']) : null,
        isReopened: m['isReopened'] ?? false,
        reopenReason: m['reopenReason'] ?? '',
        totalScore: m['totalScore'] ?? 0,
      );
}

// ══════════════════════════════════════════════════════════════
// 항목별 점수 (Score)
// ══════════════════════════════════════════════════════════════
class Score {
  final String id;
  final String submissionId;
  final String questionId;
  int score;
  String comment;
  DateTime recordedAt;

  Score({
    required this.id,
    required this.submissionId,
    required this.questionId,
    required this.score,
    this.comment = '',
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'submissionId': submissionId,
        'questionId': questionId,
        'score': score,
        'comment': comment,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory Score.fromMap(Map<String, dynamic> m) => Score(
        id: m['id'],
        submissionId: m['submissionId'],
        questionId: m['questionId'],
        score: m['score'],
        comment: m['comment'] ?? '',
        recordedAt: DateTime.parse(m['recordedAt']),
      );
}

// ══════════════════════════════════════════════════════════════
// 감사 로그 (AuditLog)
// ══════════════════════════════════════════════════════════════
class AuditLog {
  final String id;
  final String userId; // adminUser or evaluator id
  final String userType; // 'admin' | 'evaluator'
  final String userName;
  final AuditAction action;
  final String targetId; // session/submission/template id
  final String detail;
  final DateTime timestamp;
  final String ipAddress;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.action,
    required this.targetId,
    required this.detail,
    required this.timestamp,
    this.ipAddress = 'N/A',
  });

  String get actionLabel {
    switch (action) {
      case AuditAction.login: return '로그인';
      case AuditAction.logout: return '로그아웃';
      case AuditAction.sessionCreate: return '설명회 생성';
      case AuditAction.sessionEdit: return '설명회 수정';
      case AuditAction.sessionClose: return '설명회 종료';
      case AuditAction.evaluatorRegister: return '평가자 등록';
      case AuditAction.evaluatorAuth: return '평가자 인증';
      case AuditAction.submissionCreate: return '평가 제출';
      case AuditAction.submissionReopen: return '재오픈';
      case AuditAction.resultView: return '결과 조회';
      case AuditAction.resultDownload: return '결과 다운로드';
      case AuditAction.templateCreate: return '템플릿 생성';
      case AuditAction.templateEdit: return '템플릿 수정';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userType': userType,
        'userName': userName,
        'action': action.index,
        'targetId': targetId,
        'detail': detail,
        'timestamp': timestamp.toIso8601String(),
        'ipAddress': ipAddress,
      };

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'],
        userId: m['userId'],
        userType: m['userType'],
        userName: m['userName'],
        action: AuditAction.values[m['action']],
        targetId: m['targetId'],
        detail: m['detail'],
        timestamp: DateTime.parse(m['timestamp']),
        ipAddress: m['ipAddress'] ?? 'N/A',
      );
}

// ══════════════════════════════════════════════════════════════
// 집계 결과 DTO
// ══════════════════════════════════════════════════════════════
class AggregateResult {
  final String sessionId;
  final int totalEvaluators;
  final int submittedCount;
  final double submissionRate;
  final double averageTotal;
  final int maxTotal;
  final int minTotal;
  final Map<String, QuestionStats> questionStats; // questionId -> stats
  final List<EvaluatorResult> evaluatorResults;

  AggregateResult({
    required this.sessionId,
    required this.totalEvaluators,
    required this.submittedCount,
    required this.submissionRate,
    required this.averageTotal,
    required this.maxTotal,
    required this.minTotal,
    required this.questionStats,
    required this.evaluatorResults,
  });
}

class QuestionStats {
  final String questionId;
  final String questionTitle;
  final double average;
  final double stdDev;
  final int max;
  final int min;
  final int maxScore;

  QuestionStats({
    required this.questionId,
    required this.questionTitle,
    required this.average,
    required this.stdDev,
    required this.max,
    required this.min,
    required this.maxScore,
  });
}

class EvaluatorResult {
  final String evaluatorId;
  final String evaluatorName;
  final String department;
  final int totalScore;
  final bool isSubmitted;
  final Map<String, int> scoresByQuestion;

  EvaluatorResult({
    required this.evaluatorId,
    required this.evaluatorName,
    required this.department,
    required this.totalScore,
    required this.isSubmitted,
    required this.scoresByQuestion,
  });
}
