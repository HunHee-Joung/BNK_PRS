// ============================================================
// 설명회 목록 + 생성 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'session_detail_screen.dart';
import 'session_create_screen.dart';
import '../main.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final all = provider.sessions;
        final scheduled = all.where((s) => s.status == SessionStatus.scheduled).toList();
        final ongoing = all.where((s) => s.status == SessionStatus.ongoing).toList();
        final closed = all.where((s) => s.status == SessionStatus.closed).toList();

        return Column(
          children: [
            _buildHeader(context, all),
            _buildTabs(scheduled.length, ongoing.length, closed.length),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SessionTab(sessions: _filter(scheduled), onRefresh: () => provider.loadAll()),
                  _SessionTab(sessions: _filter(ongoing), onRefresh: () => provider.loadAll()),
                  _SessionTab(sessions: _filter(closed), onRefresh: () => provider.loadAll()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<EvalSession> _filter(List<EvalSession> sessions) {
    if (_searchQuery.isEmpty) return sessions;
    final q = _searchQuery.toLowerCase();
    return sessions
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.productName.toLowerCase().contains(q) ||
            s.presenterName.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildHeader(BuildContext context, List<EvalSession> all) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('설명회 관리', style: AppStyles.headlineMedium),
                    Text(
                      '총 ${all.length}개 설명회',
                      style: AppStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('설명회 생성'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: '설명회명, 제품명, 발표자 검색...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(int sCnt, int oCnt, int cCnt) {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: '진행 예정 $sCnt'),
          Tab(text: '진행 중 $oCnt'),
          Tab(text: '종료 $cCnt'),
        ],
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => const SessionCreateScreen()),
    );
    if (result == true && mounted) {
      await context.read<AppProvider>().loadAll();
    }
  }
}

class _SessionTab extends StatelessWidget {
  final List<EvalSession> sessions;
  final VoidCallback onRefresh;

  const _SessionTab({required this.sessions, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: '해당 상태의 설명회가 없습니다',
        subtitle: '상단의 설명회 생성 버튼을 눌러 새 설명회를 만드세요.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SessionCard(session: sessions[i]),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final EvalSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => rootNavigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: session.status.color.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(color: session.status.color.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title, style: AppStyles.headlineSmall),
                        const SizedBox(height: 2),
                        Text(
                          '제품: ${session.productName}',
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(session.status),
                  if (session.isLocked) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: '집계 확정 잠금',
                      child: Icon(Icons.lock, size: 16, color: AppTheme.textHint),
                    ),
                  ],
                ],
              ),
            ),
            // 상세 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _infoItem(Icons.person_outline, session.presenterName),
                  const SizedBox(width: 16),
                  _infoItem(Icons.schedule_outlined, Formatters.dateTimeKr(session.scheduledAt)),
                  const Spacer(),
                  _evaluatorCount(),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textHint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppStyles.bodySmall),
      ],
    );
  }

  Widget _evaluatorCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            '${session.evaluatorIds.length}명',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
