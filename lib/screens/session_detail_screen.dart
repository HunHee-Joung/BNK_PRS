// ============================================================
// 설명회 상세 - QR, 모니터링, 집계 결과 통합
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'session_create_screen.dart';
import 'result_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';

class SessionDetailScreen extends StatefulWidget {
  final EvalSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Submission> _submissions = [];
  List<Invitation> _invitations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      final subs = await provider.getSessionSubmissions(widget.session.id);
      final invs = await provider.getSessionInvitations(widget.session.id);
      if (mounted) {
        setState(() {
          _submissions = subs;
          _invitations = invs;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          if (!session.isLocked && session.status != SessionStatus.closed)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '수정',
              onPressed: () async {
                final ok = await rootNavigatorKey.currentState!.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SessionCreateScreen(editSession: session),
                  ),
                );
                if (ok == true && mounted) {
                  await context.read<AppProvider>().loadAll();
                  _loadData();
                }
              },
            ),
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(context, v),
            itemBuilder: (_) => [
              if (session.status == SessionStatus.scheduled)
                const PopupMenuItem(value: 'start', child: Text('설명회 시작')),
              if (session.status == SessionStatus.ongoing)
                const PopupMenuItem(value: 'close', child: Text('설명회 종료')),
              if (session.status == SessionStatus.closed && !session.isLocked)
                const PopupMenuItem(value: 'lock', child: Text('집계 확정 잠금')),
              const PopupMenuItem(value: 'result', child: Text('집계 결과 보기')),
            ],
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildStatusBar(session),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '개요 / QR'),
                Tab(text: '제출 현황'),
                Tab(text: '입장코드'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(session),
                  _buildMonitoringTab(session),
                  _buildInvitationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(EvalSession session) {
    final submitted = _submissions.where((s) => s.isSubmitted).length;
    final total = session.evaluatorIds.length;
    final rate = total > 0 ? submitted / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          StatusBadge(session.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '제출률 ${Formatters.percent(rate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('($submitted / $total명)', style: AppStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '새로고침',
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EvalSession session) {
    final qrData = 'eval://session/${session.id}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR 코드
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Text('평가자 접속 QR', style: AppStyles.headlineSmall),
                  const SizedBox(height: 4),
                  const Text(
                    '태블릿 화면에 이 QR을 표시하세요',
                    style: AppStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Session ID: ${session.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 설명회 정보
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                _infoRow('제품명', session.productName),
                const Divider(height: 24),
                _infoRow('발표자', '${session.presenterName} · ${session.presenterCompany}'),
                const Divider(height: 24),
                _infoRow('일시', Formatters.dateTimeKr(session.scheduledAt)),
                const Divider(height: 24),
                _infoRow('평가자 수', '${session.evaluatorIds.length}명'),
                if (session.notes.isNotEmpty) ...[
                  const Divider(height: 24),
                  _infoRow('메모', session.notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppStyles.labelMedium),
        ),
        Expanded(
          child: Text(value, style: AppStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildMonitoringTab(EvalSession session) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        if (_submissions.isEmpty && session.evaluatorIds.isEmpty) {
          return const EmptyState(
            icon: Icons.monitor_heart_outlined,
            title: '등록된 평가자가 없습니다',
          );
        }

        final submitted = _submissions.where((s) => s.isSubmitted).length;
        final started = _submissions.where((s) => !s.isSubmitted).length;
        final notStarted = session.evaluatorIds.length - _submissions.length;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 현황 요약 카드
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      label: '제출 완료',
                      value: '$submitted명',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      label: '진행 중',
                      value: '$started명',
                      icon: Icons.edit_outlined,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      label: '미접속',
                      value: '$notStarted명',
                      icon: Icons.person_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 파이 차트
              if (session.evaluatorIds.isNotEmpty) ...[
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: submitted.toDouble(),
                                color: AppTheme.success,
                                title: submitted > 0 ? '$submitted' : '',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: started.toDouble(),
                                color: AppTheme.warning,
                                title: started > 0 ? '$started' : '',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: notStarted.toDouble(),
                                color: AppTheme.divider,
                                title: notStarted > 0 ? '$notStarted' : '',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(AppTheme.success, '제출 완료', '$submitted명'),
                          const SizedBox(height: 8),
                          _legendItem(AppTheme.warning, '진행 중', '$started명'),
                          const SizedBox(height: 8),
                          _legendItem(AppTheme.divider, '미접속', '$notStarted명'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 평가자별 상세 목록
              const Text('평가자별 현황', style: AppStyles.headlineSmall),
              const SizedBox(height: 12),
              FutureBuilder<List<Evaluator>>(
                future: _getEvaluatorsForSession(session, provider),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final evaluators = snap.data!;
                  return Column(
                    children: evaluators.map((e) {
                      final sub = _submissions.firstWhere(
                        (s) => s.evaluatorId == e.id,
                        orElse: () => Submission(
                          id: '', sessionId: '', evaluatorId: e.id, startedAt: DateTime.now(),
                        ),
                      );
                      final hasSubmission = sub.id.isNotEmpty;
                      final isSubmitted = hasSubmission && sub.isSubmitted;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSubmitted
                                    ? AppTheme.success.withValues(alpha: 0.1)
                                    : hasSubmission
                                        ? AppTheme.warning.withValues(alpha: 0.1)
                                        : AppTheme.divider,
                                child: Text(
                                  e.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSubmitted
                                        ? AppTheme.success
                                        : hasSubmission
                                            ? AppTheme.warning
                                            : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.name, style: AppStyles.bodyMedium),
                                    Text(
                                      '${e.department} · ${e.organization}',
                                      style: AppStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isSubmitted) ...[
                                    const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                                    Text(
                                      '${sub.totalScore}점',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ] else if (hasSubmission) ...[
                                    const Icon(Icons.edit, size: 16, color: AppTheme.warning),
                                    const Text('작성 중', style: AppStyles.caption),
                                  ] else ...[
                                    const Icon(Icons.radio_button_unchecked, size: 16, color: AppTheme.textHint),
                                    const Text('미접속', style: AppStyles.caption),
                                  ],
                                ],
                              ),
                              if (isSubmitted && !session.isLocked) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18, color: AppTheme.warning),
                                  tooltip: '재오픈',
                                  onPressed: () => _reopenSubmission(sub),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Evaluator>> _getEvaluatorsForSession(
    EvalSession session, AppProvider provider,
  ) async {
    final result = <Evaluator>[];
    for (final id in session.evaluatorIds) {
      final e = provider.evaluators.firstWhere(
        (ev) => ev.id == id,
        orElse: () => Evaluator(
          id: id, name: '알 수 없음', email: '', birthDate6: '',
          department: '', organization: '', registeredAt: DateTime.now(),
        ),
      );
      result.add(e);
    }
    return result;
  }

  Widget _buildInvitationTab() {
    if (_invitations.isEmpty) {
      return const EmptyState(
        icon: Icons.vpn_key_outlined,
        title: '입장코드가 없습니다',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invitations.length,
      itemBuilder: (ctx, i) {
        final inv = _invitations[i];
        final provider = context.read<AppProvider>();
        final evaluator = provider.evaluators.firstWhere(
          (e) => e.id == inv.evaluatorId,
          orElse: () => Evaluator(
            id: inv.evaluatorId, name: '알 수 없음', email: '', birthDate6: '',
            department: '', organization: '', registeredAt: DateTime.now(),
          ),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: inv.isUsed ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.divider,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evaluator.name, style: AppStyles.bodyMedium),
                      Text(evaluator.email, style: AppStyles.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        inv.entryCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inv.isUsed ? '사용됨' : '미사용',
                      style: TextStyle(
                        fontSize: 11,
                        color: inv.isUsed ? AppTheme.success : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(Color color, String label, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppStyles.bodySmall),
        const SizedBox(width: 6),
        Text(count, style: AppStyles.labelMedium),
      ],
    );
  }

  Future<void> _reopenSubmission(Submission sub) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('제출 재오픈'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('재오픈 사유를 입력하세요. (감사 로그에 기록됩니다)'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: '예: 입력 오류 정정 요청',
                labelText: '재오픈 사유 *',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('재오픈'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      if (reasonCtrl.text.trim().isEmpty) {
        showError(context, '재오픈 사유를 입력해주세요.');
        return;
      }
      await context.read<AppProvider>().reopenSubmission(sub, reasonCtrl.text.trim());
      showSuccess(context, '제출이 재오픈되었습니다.');
      _loadData();
    }
  }

  Future<void> _handleMenu(BuildContext context, String action) async {
    final provider = context.read<AppProvider>();
    final session = widget.session;

    switch (action) {
      case 'start':
        final ok = await showConfirmDialog(
          context,
          title: '설명회 시작',
          content: '설명회를 시작합니다. 평가자들이 평가를 시작할 수 있게 됩니다.',
          confirmText: '시작',
        );
        if (ok == true && mounted) {
          await provider.startSession(session);
          showSuccess(context, '설명회가 시작되었습니다.');
          setState(() {});
        }
        break;

      case 'close':
        final ok = await showConfirmDialog(
          context,
          title: '설명회 종료',
          content: '설명회를 종료합니다. 종료 후에는 새로운 평가를 받을 수 없습니다.',
          confirmText: '종료',
          isDestructive: true,
        );
        if (ok == true && mounted) {
          await provider.closeSession(session);
          showSuccess(context, '설명회가 종료되었습니다.');
          setState(() {});
        }
        break;

      case 'lock':
        final ok = await showConfirmDialog(
          context,
          title: '집계 확정 잠금',
          content: '집계를 확정합니다. 잠금 후에는 수정이 불가능합니다.',
          confirmText: '확정 잠금',
          isDestructive: true,
        );
        if (ok == true && mounted) {
          await provider.lockSession(session);
          showSuccess(context, '집계가 확정되었습니다.');
          setState(() {});
        }
        break;

      case 'result':
        if (!mounted) return;
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => ResultScreen(session: session)),
        );
        break;
    }
  }
}
