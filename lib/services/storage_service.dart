// ============================================================
// 로컬 스토리지 서비스 (Hive + SharedPreferences)
// ============================================================

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';

const _uuid = Uuid();

class StorageService {
  static const _boxAdmins = 'admins';
  static const _boxSessions = 'sessions';
  static const _boxTemplates = 'templates';
  static const _boxEvaluators = 'evaluators';
  static const _boxInvitations = 'invitations';
  static const _boxSubmissions = 'submissions';
  static const _boxScores = 'scores';
  static const _boxAuditLogs = 'audit_logs';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  // ── 초기화 ────────────────────────────────────────────────
  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_boxAdmins),
      Hive.openBox(_boxSessions),
      Hive.openBox(_boxTemplates),
      Hive.openBox(_boxEvaluators),
      Hive.openBox(_boxInvitations),
      Hive.openBox(_boxSubmissions),
      Hive.openBox(_boxScores),
      Hive.openBox(_boxAuditLogs),
    ]);
    await _seedDefaultData();
  }

  // ── 기본 데이터 시드 ───────────────────────────────────────
  Future<void> _seedDefaultData() async {
    final adminBox = Hive.box(_boxAdmins);
    if (adminBox.isEmpty) {
      // 기본 관리자 계정: admin@eval.com / admin1234
      final admin = AdminUser(
        id: _uuid.v4(),
        name: '관리자',
        email: 'admin@eval.com',
        passwordHash: _simpleHash('admin1234'),
        role: UserRole.admin,
        department: 'IT기획부',
        createdAt: DateTime.now(),
      );
      await _saveAdmin(admin);
    }

    final templateBox = Hive.box(_boxTemplates);
    if (templateBox.isEmpty) {
      await _seedDefaultTemplates();
    }
  }

  String _simpleHash(String input) {
    // 실제 운영 시 bcrypt 또는 SHA-256 + salt 사용 권장
    var bytes = utf8.encode(input);
    var hash = bytes.fold(0, (acc, b) => (acc * 31 + b) & 0xFFFFFFFF);
    return hash.toRadixString(16).padLeft(8, '0');
  }

  bool verifyPassword(String input, String hash) => _simpleHash(input) == hash;

  Future<void> _seedDefaultTemplates() async {
    final now = DateTime.now();
    final defaultQuestions = [
      Question(id: _uuid.v4(), title: '제품 이해도', description: '제품의 구조·원리·기능에 대한 발표자의 이해 수준', maxScore: 10, orderIndex: 0),
      Question(id: _uuid.v4(), title: '시장 적합성', description: '현재 시장 환경과의 부합 정도', maxScore: 10, orderIndex: 1),
      Question(id: _uuid.v4(), title: '금융기관 고객 적합성', description: '당 기관 고객층에 대한 적합성', maxScore: 10, orderIndex: 2),
      Question(id: _uuid.v4(), title: '수익성/사업성', description: '예상 수익 및 사업 지속 가능성', maxScore: 10, orderIndex: 3),
      Question(id: _uuid.v4(), title: '리스크 관리 가능성', description: '잠재적 리스크 식별 및 관리 역량', maxScore: 10, orderIndex: 4),
      Question(id: _uuid.v4(), title: '규제/컴플라이언스 적합성', description: '금융 관련 법규 및 규정 준수 가능성', maxScore: 10, orderIndex: 5),
      Question(id: _uuid.v4(), title: '운영 안정성', description: '시스템 안정성 및 운영 체계의 신뢰도', maxScore: 10, orderIndex: 6),
      Question(id: _uuid.v4(), title: '차별성', description: '경쟁 제품 대비 차별화 요소', maxScore: 10, orderIndex: 7),
      Question(id: _uuid.v4(), title: '확장 가능성', description: '향후 기능·시장 확장 가능성', maxScore: 10, orderIndex: 8),
      Question(id: _uuid.v4(), title: '종합 평가', description: '발표 전반에 대한 종합 의견 점수', maxScore: 10, hasComment: true, orderIndex: 9),
    ];

    final template = EvalTemplate(
      id: _uuid.v4(),
      name: '금융기관 표준 평가표 (100점)',
      description: '금융기관 내부 제품 설명회 표준 평가 템플릿 (10개 항목 × 10점)',
      questions: defaultQuestions,
      createdAt: now,
      updatedAt: now,
      isDefault: true,
    );
    await saveTemplate(template);
  }

  // ══════════════════════════════════════════════════════════
  // AdminUser CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> _saveAdmin(AdminUser user) async {
    final box = Hive.box(_boxAdmins);
    await box.put(user.id, jsonEncode(user.toMap()));
  }

  Future<AdminUser?> getAdminByEmail(String email) async {
    final box = Hive.box(_boxAdmins);
    for (final key in box.keys) {
      final data = jsonDecode(box.get(key) as String) as Map<String, dynamic>;
      if (data['email'] == email) return AdminUser.fromMap(data);
    }
    return null;
  }

  Future<List<AdminUser>> getAllAdmins() async {
    final box = Hive.box(_boxAdmins);
    return box.values
        .map((v) => AdminUser.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAdmin(AdminUser user) async => _saveAdmin(user);

  // ══════════════════════════════════════════════════════════
  // Template CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveTemplate(EvalTemplate t) async {
    final box = Hive.box(_boxTemplates);
    await box.put(t.id, jsonEncode(t.toMap()));
  }

  Future<List<EvalTemplate>> getAllTemplates() async {
    final box = Hive.box(_boxTemplates);
    return box.values
        .map((v) => EvalTemplate.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<EvalTemplate?> getTemplate(String id) async {
    final box = Hive.box(_boxTemplates);
    final v = box.get(id);
    if (v == null) return null;
    return EvalTemplate.fromMap(jsonDecode(v as String) as Map<String, dynamic>);
  }

  Future<void> deleteTemplate(String id) async => Hive.box(_boxTemplates).delete(id);

  // ══════════════════════════════════════════════════════════
  // Evaluator CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveEvaluator(Evaluator e) async {
    final box = Hive.box(_boxEvaluators);
    await box.put(e.id, jsonEncode(e.toMap()));
  }

  Future<List<Evaluator>> getAllEvaluators() async {
    final box = Hive.box(_boxEvaluators);
    return box.values
        .map((v) => Evaluator.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  }

  Future<Evaluator?> getEvaluatorById(String id) async {
    final box = Hive.box(_boxEvaluators);
    final v = box.get(id);
    if (v == null) return null;
    return Evaluator.fromMap(jsonDecode(v as String) as Map<String, dynamic>);
  }

  Future<Evaluator?> findEvaluatorByEmailAndBirth(String email, String birth) async {
    final all = await getAllEvaluators();
    try {
      return all.firstWhere((e) => e.email == email && e.birthDate6 == birth);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteEvaluator(String id) async => Hive.box(_boxEvaluators).delete(id);

  // ══════════════════════════════════════════════════════════
  // Session CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveSession(EvalSession s) async {
    final box = Hive.box(_boxSessions);
    await box.put(s.id, jsonEncode(s.toMap()));
  }

  Future<List<EvalSession>> getAllSessions() async {
    final box = Hive.box(_boxSessions);
    return box.values
        .map((v) => EvalSession.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  Future<EvalSession?> getSession(String id) async {
    final box = Hive.box(_boxSessions);
    final v = box.get(id);
    if (v == null) return null;
    return EvalSession.fromMap(jsonDecode(v as String) as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async => Hive.box(_boxSessions).delete(id);

  // ══════════════════════════════════════════════════════════
  // Invitation CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveInvitation(Invitation inv) async {
    final box = Hive.box(_boxInvitations);
    await box.put(inv.id, jsonEncode(inv.toMap()));
  }

  Future<List<Invitation>> getInvitationsBySession(String sessionId) async {
    final box = Hive.box(_boxInvitations);
    return box.values
        .map((v) => Invitation.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .where((inv) => inv.sessionId == sessionId)
        .toList();
  }

  Future<Invitation?> getInvitationByToken(String token) async {
    final box = Hive.box(_boxInvitations);
    for (final key in box.keys) {
      final data = jsonDecode(box.get(key) as String) as Map<String, dynamic>;
      if (data['token'] == token) return Invitation.fromMap(data);
    }
    return null;
  }

  Future<Invitation?> getInvitationByEvaluatorAndSession(String evaluatorId, String sessionId) async {
    final box = Hive.box(_boxInvitations);
    for (final key in box.keys) {
      final data = jsonDecode(box.get(key) as String) as Map<String, dynamic>;
      if (data['evaluatorId'] == evaluatorId && data['sessionId'] == sessionId) {
        return Invitation.fromMap(data);
      }
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════
  // Submission CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveSubmission(Submission s) async {
    final box = Hive.box(_boxSubmissions);
    await box.put(s.id, jsonEncode(s.toMap()));
  }

  Future<List<Submission>> getSubmissionsBySession(String sessionId) async {
    final box = Hive.box(_boxSubmissions);
    return box.values
        .map((v) => Submission.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .where((s) => s.sessionId == sessionId)
        .toList();
  }

  Future<Submission?> getSubmissionByEvaluatorAndSession(String evaluatorId, String sessionId) async {
    final box = Hive.box(_boxSubmissions);
    for (final key in box.keys) {
      final data = jsonDecode(box.get(key) as String) as Map<String, dynamic>;
      if (data['evaluatorId'] == evaluatorId && data['sessionId'] == sessionId) {
        return Submission.fromMap(data);
      }
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════
  // Score CRUD
  // ══════════════════════════════════════════════════════════
  Future<void> saveScore(Score s) async {
    final box = Hive.box(_boxScores);
    await box.put(s.id, jsonEncode(s.toMap()));
  }

  Future<void> saveScores(List<Score> scores) async {
    final box = Hive.box(_boxScores);
    final batch = <String, String>{};
    for (final s in scores) {
      batch[s.id] = jsonEncode(s.toMap());
    }
    await box.putAll(batch);
  }

  Future<List<Score>> getScoresBySubmission(String submissionId) async {
    final box = Hive.box(_boxScores);
    return box.values
        .map((v) => Score.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .where((s) => s.submissionId == submissionId)
        .toList();
  }

  Future<List<Score>> getScoresBySession(String sessionId) async {
    final submissions = await getSubmissionsBySession(sessionId);
    final submissionIds = submissions.map((s) => s.id).toSet();
    final box = Hive.box(_boxScores);
    return box.values
        .map((v) => Score.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .where((s) => submissionIds.contains(s.submissionId))
        .toList();
  }

  // ══════════════════════════════════════════════════════════
  // AuditLog
  // ══════════════════════════════════════════════════════════
  Future<void> addAuditLog(AuditLog log) async {
    final box = Hive.box(_boxAuditLogs);
    await box.put(log.id, jsonEncode(log.toMap()));
  }

  Future<List<AuditLog>> getAllAuditLogs() async {
    final box = Hive.box(_boxAuditLogs);
    return box.values
        .map((v) => AuditLog.fromMap(jsonDecode(v as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<AuditLog>> getAuditLogsBySession(String sessionId) async {
    final all = await getAllAuditLogs();
    return all.where((l) => l.targetId == sessionId).toList();
  }

  // ══════════════════════════════════════════════════════════
  // 집계 로직
  // ══════════════════════════════════════════════════════════
  Future<AggregateResult> computeAggregate(EvalSession session, EvalTemplate template) async {
    final submissions = await getSubmissionsBySession(session.id);
    final submitted = submissions.where((s) => s.isSubmitted).toList();
    final allScores = await getScoresBySession(session.id);

    final questionStats = <String, QuestionStats>{};
    for (final q in template.questions) {
      final qScores = allScores
          .where((s) {
            final sub = submitted.firstWhere(
              (sub) => sub.id == s.submissionId,
              orElse: () => Submission(id: '', sessionId: '', evaluatorId: '', startedAt: DateTime.now()),
            );
            return sub.id.isNotEmpty && s.questionId == q.id;
          })
          .map((s) => s.score)
          .toList();

      double avg = 0, stdDev = 0;
      int mx = 0, mn = 0;
      if (qScores.isNotEmpty) {
        avg = qScores.reduce((a, b) => a + b) / qScores.length;
        mx = qScores.reduce((a, b) => a > b ? a : b);
        mn = qScores.reduce((a, b) => a < b ? a : b);
        final variance = qScores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) / qScores.length;
        stdDev = variance > 0 ? variance.abs().clamp(0.0, double.infinity) : 0;
        // sqrt approximation
        if (stdDev > 0) stdDev = _sqrt(stdDev);
      }
      questionStats[q.id] = QuestionStats(
        questionId: q.id,
        questionTitle: q.title,
        average: avg,
        stdDev: stdDev,
        max: mx,
        min: mn,
        maxScore: q.maxScore,
      );
    }

    // 평가자별 결과
    final evaluatorResults = <EvaluatorResult>[];
    for (final sub in submissions) {
      final evaluator = await getEvaluatorById(sub.evaluatorId);
      final scores = allScores.where((s) => s.submissionId == sub.id).toList();
      final scoreMap = <String, int>{};
      for (final s in scores) {
        scoreMap[s.questionId] = s.score;
      }
      evaluatorResults.add(EvaluatorResult(
        evaluatorId: sub.evaluatorId,
        evaluatorName: evaluator?.name ?? '알 수 없음',
        department: evaluator?.department ?? '',
        totalScore: sub.totalScore,
        isSubmitted: sub.isSubmitted,
        scoresByQuestion: scoreMap,
      ));
    }
    evaluatorResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final totals = submitted.map((s) => s.totalScore).toList();
    final avgTotal = totals.isEmpty ? 0.0 : totals.reduce((a, b) => a + b) / totals.length;
    final maxTotal = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);
    final minTotal = totals.isEmpty ? 0 : totals.reduce((a, b) => a < b ? a : b);

    return AggregateResult(
      sessionId: session.id,
      totalEvaluators: session.evaluatorIds.length,
      submittedCount: submitted.length,
      submissionRate: session.evaluatorIds.isEmpty
          ? 0
          : submitted.length / session.evaluatorIds.length,
      averageTotal: avgTotal,
      maxTotal: maxTotal,
      minTotal: minTotal,
      questionStats: questionStats,
      evaluatorResults: evaluatorResults,
    );
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
    return r;
  }

  // ── 헬퍼: 새 ID 생성 ──────────────────────────────────────
  String newId() => _uuid.v4();
}
