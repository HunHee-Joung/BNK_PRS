// ============================================================
// 평가자 관리 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class EvaluatorListScreen extends StatefulWidget {
  const EvaluatorListScreen({super.key});

  @override
  State<EvaluatorListScreen> createState() => _EvaluatorListScreenState();
}

class _EvaluatorListScreenState extends State<EvaluatorListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final evaluators = provider.evaluators
            .where((e) => _searchQuery.isEmpty ||
                e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.department.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Column(
          children: [
            _buildHeader(context, provider.evaluators.length),
            Expanded(
              child: evaluators.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: _searchQuery.isEmpty ? '등록된 평가자가 없습니다' : '검색 결과가 없습니다',
                      subtitle: '오른쪽 상단의 + 버튼을 눌러 평가자를 등록하세요.',
                      action: ElevatedButton.icon(
                        onPressed: () => _openRegister(context),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('평가자 등록'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: evaluators.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EvaluatorCard(
                          evaluator: evaluators[i],
                          onDelete: () => _delete(context, evaluators[i]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
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
                    const Text('평가자 관리', style: AppStyles.headlineMedium),
                    Text('총 $total명 등록', style: AppStyles.bodySmall),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openRegister(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('평가자 등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: '이름, 이메일, 부서 검색...',
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

  void _openRegister(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EvaluatorRegisterSheet(),
    );
  }

  Future<void> _delete(BuildContext context, Evaluator evaluator) async {
    final ok = await showConfirmDialog(
      context,
      title: '평가자 삭제',
      content: '\'${evaluator.name}\' 평가자를 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    );
    if (ok == true && context.mounted) {
      await context.read<AppProvider>().deleteEvaluator(evaluator.id);
      showSuccess(context, '평가자가 삭제되었습니다.');
    }
  }
}

class _EvaluatorCard extends StatelessWidget {
  final Evaluator evaluator;
  final VoidCallback onDelete;

  const _EvaluatorCard({required this.evaluator, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              evaluator.name.substring(0, 1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(evaluator.name, style: AppStyles.headlineSmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: evaluator.isActive ? AppTheme.primaryLight : AppTheme.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        evaluator.isActive ? '활성' : '비활성',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: evaluator.isActive ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(evaluator.email, style: AppStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${evaluator.department} · ${evaluator.organization}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '등록 ${Formatters.date(evaluator.registeredAt)}',
                style: AppStyles.caption,
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                onPressed: onDelete,
                tooltip: '삭제',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 평가자 등록 바텀시트 ────────────────────────────────────────
class _EvaluatorRegisterSheet extends StatefulWidget {
  const _EvaluatorRegisterSheet();

  @override
  State<_EvaluatorRegisterSheet> createState() => _EvaluatorRegisterSheetState();
}

class _EvaluatorRegisterSheetState extends State<_EvaluatorRegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showBirth = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _birthCtrl.dispose();
    _deptCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('평가자 등록', style: AppStyles.headlineMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 개인정보 안내 배너
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.privacy_tip_outlined, size: 16, color: AppTheme.warning),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '생년월일은 인증 목적으로만 사용되며, 암호화하여 보관됩니다. '
                                '개인정보 수집·이용에 대한 동의를 사전에 받아야 합니다.',
                                style: TextStyle(fontSize: 11, color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: '이름 *'),
                              validator: (v) => v?.trim().isEmpty == true ? '이름을 입력하세요' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _orgCtrl,
                              decoration: const InputDecoration(labelText: '소속기관 *'),
                              validator: (v) => v?.trim().isEmpty == true ? '소속기관을 입력하세요' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: '이메일 *',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
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
                        controller: _deptCtrl,
                        decoration: const InputDecoration(labelText: '부서/직책'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthCtrl,
                        obscureText: !_showBirth,
                        decoration: InputDecoration(
                          labelText: '생년월일 6자리 * (예: 850115)',
                          hintText: 'YYMMDD',
                          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showBirth ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _showBirth = !_showBirth),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (v) {
                          if (v?.isEmpty == true) return '생년월일을 입력하세요';
                          if (v!.length != 6) return '6자리로 입력하세요';
                          if (!RegExp(r'^\d{6}$').hasMatch(v)) return '숫자만 입력하세요';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().registerEvaluator(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        birthDate6: _birthCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
        organization: _orgCtrl.text.trim(),
      );
      if (mounted) {
        showSuccess(context, '평가자가 등록되었습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
