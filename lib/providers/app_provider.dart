// ============================================================
// 앱 전역 상태 관리 Provider
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  // ── 인증 상태 ──────────────────────────────────────────────
  AdminUser? _currentAdmin;
  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;

  // ── 현재 평가자 (평가자 모드) ──────────────────────────────
  Evaluator? _currentEvaluator;
  Evaluator? get currentEvaluator => _currentEvaluator;
  EvalSession? _currentEvalSession;
  EvalSession? get currentEvalSession => _currentEvalSession;

  // ── 데이터 목록 ────────────────────────────────────────────
  List<EvalSession> _sessions = [];
  List<EvalSession> get sessions => _sessions;

  List<EvalTemplate> _templates = [];
  List<EvalTemplate> get templates => _templates;

  List<Evaluator> _evaluators = [];
  List<Evaluator> get evaluators => _evaluators;

  List<AuditLog> _auditLogs = [];
  List<AuditLog> get auditLogs => _auditLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ══════════════════════════════════════════════════════════
  // 초기 로드
  // ══════════════════════════════════════════════════════════
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _storage.getAllSessions();
      _templates = await _storage.getAllTemplates();
      _evaluators = await _storage.getAllEvaluators();
      _auditLogs = await _storage.getAllAuditLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════
  // 관리자 인증
  // ══════════════════════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    final admin = await _storage.getAdminByEmail(email);
    if (admin == null) return false;
    if (!_storage.verifyPassword(password, admin.passwordHash)) return false;
    if (!admin.isActive) return false;

    admin.lastLoginAt = DateTime.now();
    await _storage.updateAdmin(admin);
    _currentAdmin = admin;

    await _addAuditLog(
      userId: admin.id,
      userType: 'admin',
      userName: admin.name,
      action: AuditAction.login,
      targetId: admin.id,
      detail: '관리자 로그인: ${admin.email}',
    );

    await loadAll();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_currentAdmin != null) {
      await _addAuditLog(
        userId: _currentAdmin!.id,
        userType: 'admin',
        userName: _currentAdmin!.name,
        action: AuditAction.logout,
        targetId: _currentAdmin!.id,
        detail: '관리자 로그아웃',
      );
    }
    _currentAdmin = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // 평가자 인증
  // ══════════════════════════════════════════════════════════
  Future<bool> authenticateEvaluator({
    required String sessionId,
    required String email,
    required String birthDate6,
    required String entryCode,
  }) async {
    final evaluator = await _storage.findEvaluatorByEmailAndBirth(email, birthDate6);
    if (evaluator == null) return false;

    final session = await _storage.getSession(sessionId);
    if (session == null) return false;
    if (!session.evaluatorIds.contains(evaluator.id)) return false;
    if (session.status == SessionStatus.closed) return false;

    final inv = await _storage.getInvitationByEvaluatorAndSession(evaluator.id, sessionId);
    if (inv != null && inv.entryCode != entryCode) return false;

    _currentEvaluator = evaluator;
    _currentEvalSession = session;

    if (inv != null && !inv.isUsed) {
      inv.isUsed = true;
      inv.usedAt = DateTime.now();
      await _storage.saveInvitation(inv);
    }

    await _addAuditLog(
      userId: evaluator.id,
      userType: 'evaluator',
      userName: evaluator.name,
      action: AuditAction.evaluatorAuth,
      targetId: sessionId,
      detail: '평가자 인증 성공: ${evaluator.email}',
    );

    notifyListeners();
    return true;
  }

  void clearEvaluatorSession() {
    _currentEvaluator = null;
    _currentEvalSession = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // 설명회 관리
  // ══════════════════════════════════════════════════════════
  Future<EvalSession> createSession({
    required String title,
    required String productName,
    required String presenterName,
    required String presenterCompany,
    required DateTime scheduledAt,
    required String templateId,
    required List<String> evaluatorIds,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final session = EvalSession(
      id: _storage.newId(),
      title: title,
      productName: productName,
      presenterName: presenterName,
      presenterCompany: presenterCompany,
      scheduledAt: scheduledAt,
      templateId: templateId,
      evaluatorIds: evaluatorIds,
      createdBy: _currentAdmin?.id ?? 'system',
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );
    await _storage.saveSession(session);

    // 초대 토큰 생성
    await _generateInvitations(session);

    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.sessionCreate,
      targetId: session.id,
      detail: '설명회 생성: ${session.title}',
    );

    await loadAll();
    return session;
  }

  Future<void> _generateInvitations(EvalSession session) async {
    for (final evalId in session.evaluatorIds) {
      final existing = await _storage.getInvitationByEvaluatorAndSession(evalId, session.id);
      if (existing != null) continue;

      final inv = Invitation(
        id: _storage.newId(),
        sessionId: session.id,
        evaluatorId: evalId,
        token: _storage.newId(),
        entryCode: _generateEntryCode(),
        expiresAt: session.scheduledAt.add(const Duration(hours: 24)),
      );
      await _storage.saveInvitation(inv);
    }
  }

  String _generateEntryCode() {
    final ts = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return ts.toString();
  }

  Future<void> updateSession(EvalSession session) async {
    session.updatedAt = DateTime.now();
    await _storage.saveSession(session);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.sessionEdit,
      targetId: session.id,
      detail: '설명회 수정: ${session.title}',
    );
    await loadAll();
  }

  Future<void> startSession(EvalSession session) async {
    session.status = SessionStatus.ongoing;
    await updateSession(session);
  }

  Future<void> closeSession(EvalSession session) async {
    session.status = SessionStatus.closed;
    session.closedAt = DateTime.now();
    await updateSession(session);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.sessionClose,
      targetId: session.id,
      detail: '설명회 종료: ${session.title}',
    );
  }

  Future<void> lockSession(EvalSession session) async {
    session.isLocked = true;
    await updateSession(session);
  }

  // ══════════════════════════════════════════════════════════
  // 템플릿 관리
  // ══════════════════════════════════════════════════════════
  Future<EvalTemplate> createTemplate({
    required String name,
    required String description,
    required List<Question> questions,
  }) async {
    final now = DateTime.now();
    final template = EvalTemplate(
      id: _storage.newId(),
      name: name,
      description: description,
      questions: questions,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.saveTemplate(template);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.templateCreate,
      targetId: template.id,
      detail: '템플릿 생성: ${template.name}',
    );
    await loadAll();
    return template;
  }

  Future<void> updateTemplate(EvalTemplate template) async {
    template.updatedAt = DateTime.now();
    await _storage.saveTemplate(template);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.templateEdit,
      targetId: template.id,
      detail: '템플릿 수정: ${template.name}',
    );
    await loadAll();
  }

  Future<void> deleteTemplate(String id) async {
    await _storage.deleteTemplate(id);
    await loadAll();
  }

  // ══════════════════════════════════════════════════════════
  // 평가자 관리
  // ══════════════════════════════════════════════════════════
  Future<Evaluator> registerEvaluator({
    required String name,
    required String email,
    required String birthDate6,
    required String department,
    required String organization,
  }) async {
    final evaluator = Evaluator(
      id: _storage.newId(),
      name: name,
      email: email,
      birthDate6: birthDate6,
      department: department,
      organization: organization,
      registeredAt: DateTime.now(),
    );
    await _storage.saveEvaluator(evaluator);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.evaluatorRegister,
      targetId: evaluator.id,
      detail: '평가자 등록: ${evaluator.name} (${evaluator.email})',
    );
    await loadAll();
    return evaluator;
  }

  Future<void> deleteEvaluator(String id) async {
    await _storage.deleteEvaluator(id);
    await loadAll();
  }

  // ══════════════════════════════════════════════════════════
  // 평가 제출
  // ══════════════════════════════════════════════════════════
  Future<Submission> getOrCreateSubmission(String sessionId, String evaluatorId) async {
    var sub = await _storage.getSubmissionByEvaluatorAndSession(evaluatorId, sessionId);
    if (sub != null) return sub;

    sub = Submission(
      id: _storage.newId(),
      sessionId: sessionId,
      evaluatorId: evaluatorId,
      startedAt: DateTime.now(),
    );
    await _storage.saveSubmission(sub);
    return sub;
  }

  Future<void> submitEvaluation({
    required String submissionId,
    required String sessionId,
    required String evaluatorId,
    required List<Score> scores,
  }) async {
    final sub = await _storage.getSubmissionByEvaluatorAndSession(evaluatorId, sessionId);
    if (sub == null) return;
    if (sub.isSubmitted && !sub.isReopened) return; // 제출 후 수정 불가

    final total = scores.fold(0, (sum, s) => sum + s.score);
    sub.isSubmitted = true;
    sub.submittedAt = DateTime.now();
    sub.lastModifiedAt = DateTime.now();
    sub.totalScore = total;
    sub.isReopened = false;

    await _storage.saveScores(scores);
    await _storage.saveSubmission(sub);

    await _addAuditLog(
      userId: evaluatorId,
      userType: 'evaluator',
      userName: _currentEvaluator?.name ?? '평가자',
      action: AuditAction.submissionCreate,
      targetId: sessionId,
      detail: '평가 제출 완료: 총점 $total점',
    );
  }

  Future<void> reopenSubmission(Submission sub, String reason) async {
    sub.isReopened = true;
    sub.reopenReason = reason;
    await _storage.saveSubmission(sub);
    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.submissionReopen,
      targetId: sub.sessionId,
      detail: '제출 재오픈: ${sub.evaluatorId} - 사유: $reason',
    );
  }

  // ══════════════════════════════════════════════════════════
  // 집계
  // ══════════════════════════════════════════════════════════
  Future<AggregateResult?> getAggregateResult(EvalSession session) async {
    final template = await _storage.getTemplate(session.templateId);
    if (template == null) return null;

    await _addAuditLog(
      userId: _currentAdmin?.id ?? 'system',
      userType: 'admin',
      userName: _currentAdmin?.name ?? 'system',
      action: AuditAction.resultView,
      targetId: session.id,
      detail: '집계 결과 조회: ${session.title}',
    );

    return _storage.computeAggregate(session, template);
  }

  Future<List<Submission>> getSessionSubmissions(String sessionId) =>
      _storage.getSubmissionsBySession(sessionId);

  Future<List<Score>> getSubmissionScores(String submissionId) =>
      _storage.getScoresBySubmission(submissionId);

  Future<List<Invitation>> getSessionInvitations(String sessionId) =>
      _storage.getInvitationsBySession(sessionId);

  Future<EvalTemplate?> getTemplate(String id) => _storage.getTemplate(id);

  // ══════════════════════════════════════════════════════════
  // 감사 로그
  // ══════════════════════════════════════════════════════════
  Future<void> _addAuditLog({
    required String userId,
    required String userType,
    required String userName,
    required AuditAction action,
    required String targetId,
    required String detail,
  }) async {
    final log = AuditLog(
      id: _storage.newId(),
      userId: userId,
      userType: userType,
      userName: userName,
      action: action,
      targetId: targetId,
      detail: detail,
      timestamp: DateTime.now(),
    );
    await _storage.addAuditLog(log);
    _auditLogs = [log, ..._auditLogs];
  }

  Future<void> refreshAuditLogs() async {
    _auditLogs = await _storage.getAllAuditLogs();
    notifyListeners();
  }

  Future<List<AuditLog>> getSessionAuditLogs(String sessionId) =>
      _storage.getAuditLogsBySession(sessionId);
}
