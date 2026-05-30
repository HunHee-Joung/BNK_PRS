// ============================================================
// 평가자 인증 화면 + 평가 입력 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

// ══════════════════════════════════════════════════════════════
// 평가자 인증 화면
// ══════════════════════════════════════════════════════════════
class EvaluatorAuthScreen extends StatefulWidget {
  final String? sessionId; // QR에서 전달받은 세션 ID
  const EvaluatorAuthScreen({super.key, this.sessionId});

  @override
  State<EvaluatorAuthScreen> createState() => _EvaluatorAuthScreenState();
}

class _EvaluatorAuthScreenState extends State<EvaluatorAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _obscureBirth = true;
  bool _isLoading = false;
  int _step = 0; // 0: 세션ID 입력, 1: 인증 정보

  EvalSession? _foundSession;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _sessionIdCtrl.text = widget.sessionId!;
      _step = 1;
      _checkSession();
    }
  }

  @override
  void dispose() {
    _sessionIdCtrl.dispose();
    _emailCtrl.dispose();
    _birthCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final storage = StorageService.instance;
    final session = await storage.getSession(_sessionIdCtrl.text.trim());
    if (mounted) {
      if (session == null) {
        showError(context, '유효하지 않은 설명회 ID입니다.');
      } else if (session.status == SessionStatus.closed) {
        showError(context, '이미 종료된 설명회입니다.');
      } else if (session.status == SessionStatus.scheduled) {
        showError(context, '아직 시작되지 않은 설명회입니다.');
      } else {
        setState(() {
          _foundSession = session;
          _step = 1;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foundSession == null) return;

    setState(() => _isLoading = true);
    try {
      final ok = await context.read<AppProvider>().authenticateEvaluator(
        sessionId: _foundSession!.id,
        email: _emailCtrl.text.trim(),
        birthDate6: _birthCtrl.text.trim(),
        entryCode: _codeCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EvaluationScreen(session: _foundSession!)),
        );
      } else {
        showError(context, '인증 정보가 올바르지 않습니다.\n이메일, 생년월일, 입장코드를 확인해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('평가자 접속'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.how_to_vote_outlined, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '제품 설명회 평가',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              Text(
                                '본인 인증 후 평가를 시작합니다',
                                style: TextStyle(fontSize: 13, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_step == 0) _buildStep0() else _buildStep1(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('설명회 ID 입력', style: AppStyles.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'QR 코드를 스캔하거나 관리자에게 받은 설명회 ID를 입력하세요.',
            style: AppStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _sessionIdCtrl,
            decoration: const InputDecoration(
              labelText: '설명회 ID',
              hintText: 'xxxxxxxx-xxxx-...',
              prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
            ),
            onSubmitted: (_) => _checkSession(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkSession,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            child: const Text('다음', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: '인증 중...',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_foundSession != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: AppTheme.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundSession!.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '제품: ${_foundSession!.productName}',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text('본인 인증', style: AppStyles.headlineSmall),
              const SizedBox(height: 4),
              const Text(
                '사전 등록된 정보로 본인 인증을 완료해주세요.',
                style: AppStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: '등록된 이메일 *',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isEmpty == true) return '이메일을 입력하세요';
                  if (!v!.contains('@')) return '올바른 이메일 형식이 아닙니다';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthCtrl,
                obscureText: _obscureBirth,
                decoration: InputDecoration(
                  labelText: '생년월일 6자리 *',
                  hintText: 'YYMMDD (예: 850115)',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureBirth ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureBirth = !_obscureBirth),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) {
                  if (v?.isEmpty == true) return '생년월일을 입력하세요';
                  if (v!.length != 6) return '6자리로 입력하세요';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: '입장코드 *',
                  hintText: '관리자에게 받은 6자리 코드',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) {
                  if (v?.trim().isEmpty == true) return '입장코드를 입력하세요';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('평가 시작', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _step = 0),
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                child: const Text('← 설명회 ID 재입력'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 평가 입력 화면
// ══════════════════════════════════════════════════════════════
class EvaluationScreen extends StatefulWidget {
  final EvalSession session;
  const EvaluationScreen({super.key, required this.session});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  EvalTemplate? _template;
  Submission? _submission;
  Map<String, int> _scores = {};
  Map<String, String> _comments = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      final evaluator = provider.currentEvaluator;
      if (evaluator == null) return;

      final template = await provider.getTemplate(widget.session.templateId);
      final sub = await provider.getOrCreateSubmission(widget.session.id, evaluator.id);

      // 기존 점수 로드
      if (sub.isSubmitted || sub.isReopened) {
        final existingScores = await provider.getSubmissionScores(sub.id);
        final scoreMap = <String, int>{};
        final commentMap = <String, String>{};
        for (final s in existingScores) {
          scoreMap[s.questionId] = s.score;
          if (s.comment.isNotEmpty) commentMap[s.questionId] = s.comment;
        }
        if (mounted) {
          setState(() {
            _scores = scoreMap;
            _comments = commentMap;
          });
        }
      }

      if (mounted) {
        setState(() {
          _template = template;
          _submission = sub;
          _isSubmitted = sub.isSubmitted && !sub.isReopened;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_template == null || _submission == null) return;

    // 필수 항목 검사
    final required = _template!.questions.where((q) => q.isRequired);
    final missing = required.where((q) => (_scores[q.id] ?? 0) == 0).toList();
    if (missing.isNotEmpty) {
      showError(context, '미입력 필수 항목이 있습니다: ${missing.map((q) => q.title).join(', ')}');
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: '평가 제출',
      content: '평가를 최종 제출하시겠습니까?\n제출 후에는 수정할 수 없습니다.',
      confirmText: '제출',
    );
    if (ok != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<AppProvider>();
      final evaluator = provider.currentEvaluator!;
      final now = DateTime.now();
      final scores = _template!.questions.map((q) => Score(
        id: StorageService.instance.newId(),
        submissionId: _submission!.id,
        questionId: q.id,
        score: _scores[q.id] ?? 0,
        comment: _comments[q.id] ?? '',
        recordedAt: now,
      )).toList();

      await provider.submitEvaluation(
        submissionId: _submission!.id,
        sessionId: widget.session.id,
        evaluatorId: evaluator.id,
        scores: scores,
      );

      if (mounted) {
        setState(() => _isSubmitted = true);
        showSuccess(context, '평가가 제출되었습니다. 감사합니다!');
      }
    } catch (e) {
      if (mounted) showError(context, '제출 오류: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final evaluator = provider.currentEvaluator;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSubmitted) {
      return _buildSubmittedView(evaluator);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.session.title),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              provider.clearEvaluatorSession();
              Navigator.of(context).pop();
            },
            child: const Text('종료'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _buildProgressBar(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        message: '제출 중...',
        child: Column(
          children: [
            _buildEvalHeader(evaluator),
            Expanded(
              child: _template == null
                  ? const Center(child: Text('평가 템플릿을 찾을 수 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _template!.questions.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionCard(
                          question: _template!.questions[i],
                          index: i,
                          currentScore: _scores[_template!.questions[i].id] ?? 0,
                          currentComment: _comments[_template!.questions[i].id] ?? '',
                          onScoreChanged: (score) {
                            setState(() => _scores[_template!.questions[i].id] = score);
                          },
                          onCommentChanged: (comment) {
                            setState(() => _comments[_template!.questions[i].id] = comment);
                          },
                        ),
                      ),
                    ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_template == null) return const SizedBox.shrink();
    final answered = _template!.questions.where((q) => (_scores[q.id] ?? 0) > 0).length;
    final total = _template!.questions.length;
    return LinearProgressIndicator(
      value: total > 0 ? answered / total : 0,
      backgroundColor: AppTheme.divider,
      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
      minHeight: 4,
    );
  }

  Widget _buildEvalHeader(Evaluator? evaluator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              evaluator?.name.substring(0, 1) ?? '?',
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evaluator?.name ?? '', style: AppStyles.bodyMedium),
                Text('${evaluator?.department} · ${evaluator?.organization}', style: AppStyles.caption),
              ],
            ),
          ),
          if (_template != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_scores.values.fold(0, (a, b) => a + b)} / ${_template!.totalScore}점',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary,
                  ),
                ),
                Text(
                  '${_template!.questions.where((q) => (_scores[q.id] ?? 0) > 0).length}'
                  ' / ${_template!.questions.length}개 답변',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: AppTheme.primary,
        ),
        child: const Text(
          '평가 최종 제출',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSubmittedView(Evaluator? evaluator) {
    final total = _scores.values.fold(0, (a, b) => a + b);
    final maxTotal = _template?.totalScore ?? 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
                ),
                const SizedBox(height: 24),
                const Text('평가가 완료되었습니다!', style: AppStyles.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  '${evaluator?.name ?? ''}님의 평가가 성공적으로 제출되었습니다.',
                  style: AppStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$total점',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '총 $maxTotal점 만점',
                        style: AppStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      ScoreGaugeBar(score: total.toDouble(), maxScore: maxTotal.toDouble()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '평가 결과는 관리자에게 자동으로 전달되었습니다.\n이 화면을 닫으셔도 됩니다.',
                  style: AppStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    context.read<AppProvider>().clearEvaluatorSession();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                  child: const Text('화면 닫기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 평가 문항 카드 ─────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final int currentScore;
  final String currentComment;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<String> onCommentChanged;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.currentScore,
    required this.currentComment,
    required this.onScoreChanged,
    required this.onCommentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = currentScore > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.divider,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문항 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isAnswered ? AppTheme.primary : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isAnswered ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(question.title, style: AppStyles.headlineSmall),
                          if (question.isRequired) ...[
                            const SizedBox(width: 4),
                            const Text(' *', style: TextStyle(color: AppTheme.error, fontSize: 16)),
                          ],
                        ],
                      ),
                      if (question.description.isNotEmpty)
                        Text(question.description, style: AppStyles.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currentScore',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isAnswered ? AppTheme.primary : AppTheme.textHint,
                      ),
                    ),
                    Text(
                      '/ ${question.maxScore}점',
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 점수 입력 - 1~10 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(question.maxScore, (i) {
                final score = i + 1;
                final isSelected = currentScore == score;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => onScoreChanged(score),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 점수 게이지
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ScoreGaugeBar(
              score: currentScore.toDouble(),
              maxScore: question.maxScore.toDouble(),
            ),
          ),

          // 코멘트 입력
          if (question.hasComment) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: onCommentChanged,
                controller: TextEditingController(text: currentComment),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '코멘트를 입력하세요 (선택)',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textHint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
