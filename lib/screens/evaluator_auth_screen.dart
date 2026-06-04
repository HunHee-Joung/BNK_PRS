// ============================================================
// 평가자 인증 화면 (입장코드 단독 진입) + 평가 입력 화면
//
// UX 원칙:
//   - 평가자는 관리자에게 받은 "입장코드" 1개만 입력
//   - QR 스캔 시 자동 채워서 즉시 진입
//   - 본인확인은 코드 발급 시점에 관리자가 완료한 것으로 간주
//     (1회용 코드 + 만료 시간으로 보안 확보)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

// ══════════════════════════════════════════════════════════════
// 평가자 인증 화면 (입장코드 단독 진입)
// ══════════════════════════════════════════════════════════════
class EvaluatorAuthScreen extends StatefulWidget {
  /// QR 스캔 시 자동 채워질 입장코드 (선택)
  final String? prefilledEntryCode;

  /// (Legacy) 이전 버전 호환용 sessionId 파라미터
  /// → 더 이상 사용되지 않음. prefilledEntryCode 사용 권장
  final String? sessionId;

  const EvaluatorAuthScreen({
    super.key,
    this.prefilledEntryCode,
    this.sessionId,
  });

  @override
  State<EvaluatorAuthScreen> createState() => _EvaluatorAuthScreenState();
}

class _EvaluatorAuthScreenState extends State<EvaluatorAuthScreen> {
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEntryCode != null && widget.prefilledEntryCode!.isNotEmpty) {
      _codeCtrl.text = widget.prefilledEntryCode!.toUpperCase();
      // QR로 진입한 경우 자동 인증 시도
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = '입장코드를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AppProvider>().authenticateByEntryCode(code);
      if (!mounted) return;

      if (result.ok && result.session != null) {
        // 인증 성공 → 평가 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EvaluationScreen(session: result.session!)),
        );
      } else {
        setState(() => _errorMessage = result.errorMessage ?? '인증에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '오류가 발생했습니다: $e');
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildCodeInputCard(),
                  const SizedBox(height: 16),
                  _buildHelpCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                  '입장코드를 입력하여 평가를 시작하세요',
                  style: TextStyle(fontSize: 13, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInputCard() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('입장코드 입력', style: AppStyles.headlineSmall),
            const SizedBox(height: 4),
            const Text(
              '관리자에게 받은 입장코드를 입력하세요.\n예: A7K9-X3M2',
              style: AppStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                // 자동 대문자 변환 + 영숫자/하이픈만 허용
                _UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                LengthLimitingTextInputFormatter(9), // XXXX-XXXX
              ],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX',
                hintStyle: TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  color: AppTheme.textHint.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                errorText: _errorMessage,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => _authenticate(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _authenticate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                '평가 시작',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_outline, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '입장코드를 받지 못하셨나요?',
                  style: AppStyles.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '평가 진행 담당자에게 본인의 입장코드를 요청하세요. '
                  '코드는 평가자 1명당 1개씩 발급되며, 1회 사용 후 만료됩니다.',
                  style: AppStyles.bodySmall.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력 시 자동으로 대문자 변환
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
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
