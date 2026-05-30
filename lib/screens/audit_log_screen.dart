// ============================================================
// 감사 로그 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _searchQuery = '';
  AuditAction? _filterAction;
  String _filterUserType = 'all'; // all | admin | evaluator

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final logs = _applyFilters(provider.auditLogs);
        return Column(
          children: [
            _buildHeader(context, provider.auditLogs.length, logs.length),
            _buildFilterBar(),
            Expanded(
              child: logs.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_outlined,
                      title: '감사 로그가 없습니다',
                      subtitle: '시스템 사용 기록이 없습니다.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.refreshAuditLogs(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: logs.length,
                        itemBuilder: (ctx, i) => _AuditLogItem(log: logs[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<AuditLog> _applyFilters(List<AuditLog> logs) {
    return logs.where((log) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!log.userName.toLowerCase().contains(q) &&
            !log.detail.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterAction != null && log.action != _filterAction) return false;
      if (_filterUserType == 'admin' && log.userType != 'admin') return false;
      if (_filterUserType == 'evaluator' && log.userType != 'evaluator') return false;
      return true;
    }).toList();
  }

  Widget _buildHeader(BuildContext context, int total, int filtered) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('감사 로그', style: AppStyles.headlineMedium),
                    Text(
                      '총 $total건 · 표시 $filtered건',
                      style: AppStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, size: 14, color: AppTheme.warning),
                    SizedBox(width: 4),
                    Text(
                      '보안 감사용',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: '사용자명, 상세 내용 검색...',
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 사용자 타입 필터
            _filterChip('전체', _filterUserType == 'all', () => setState(() => _filterUserType = 'all')),
            const SizedBox(width: 6),
            _filterChip('관리자', _filterUserType == 'admin', () => setState(() => _filterUserType = 'admin')),
            const SizedBox(width: 6),
            _filterChip('평가자', _filterUserType == 'evaluator', () => setState(() => _filterUserType = 'evaluator')),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: AppTheme.divider),
            const SizedBox(width: 12),
            // 액션 필터
            _actionFilterChip(null, '전체 액션'),
            const SizedBox(width: 6),
            _actionFilterChip(AuditAction.login, '로그인'),
            const SizedBox(width: 6),
            _actionFilterChip(AuditAction.submissionCreate, '평가 제출'),
            const SizedBox(width: 6),
            _actionFilterChip(AuditAction.resultDownload, '다운로드'),
            const SizedBox(width: 6),
            _actionFilterChip(AuditAction.sessionCreate, '설명회 생성'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _actionFilterChip(AuditAction? action, String label) {
    final isSelected = _filterAction == action;
    return InkWell(
      onTap: () => setState(() => _filterAction = action),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary.withValues(alpha: 0.1) : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final AuditLog log;
  const _AuditLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 액션 아이콘
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(log.action.icon, size: 16, color: log.action.color),
          ),
          const SizedBox(width: 12),
          // 상세 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.userType == 'admin'
                            ? AppTheme.info.withValues(alpha: 0.1)
                            : AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.userType == 'admin' ? '관리자' : '평가자',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: log.userType == 'admin' ? AppTheme.info : AppTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(log.userName, style: AppStyles.labelLarge),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: log.action.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log.detail, style: AppStyles.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 11, color: AppTheme.textHint),
                    const SizedBox(width: 3),
                    Text(
                      Formatters.dateTime(log.timestamp),
                      style: AppStyles.caption,
                    ),
                    if (log.ipAddress != 'N/A') ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.computer, size: 11, color: AppTheme.textHint),
                      const SizedBox(width: 3),
                      Text(log.ipAddress, style: AppStyles.caption),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
