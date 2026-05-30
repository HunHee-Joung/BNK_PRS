// ============================================================
// 평가 템플릿 관리 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';

const _uuid = Uuid();

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final templates = provider.templates;
        return Column(
          children: [
            PageHeader(
              title: '평가 템플릿',
              subtitle: '총 ${templates.length}개 템플릿',
              actions: [
                ElevatedButton.icon(
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('템플릿 생성'),
                ),
              ],
            ),
            Expanded(
              child: templates.isEmpty
                  ? EmptyState(
                      icon: Icons.description_outlined,
                      title: '등록된 템플릿이 없습니다',
                      subtitle: '새 템플릿을 생성하거나 기본 템플릿을 사용하세요.',
                      action: ElevatedButton(
                        onPressed: () => _openCreate(context),
                        child: const Text('템플릿 생성'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: templates.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TemplateCard(template: templates[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openCreate(BuildContext context) {
    rootNavigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const TemplateEditScreen()),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final EvalTemplate template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: template.isDefault
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.divider,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(template.name, style: AppStyles.headlineSmall),
                          if (template.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '기본',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (template.description.isNotEmpty)
                        Text(template.description, style: AppStyles.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _handleMenu(context, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    if (!template.isDefault)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(color: AppTheme.error)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 문항 요약
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _statChip(Icons.format_list_numbered, '${template.questions.length}개 항목'),
                    const SizedBox(width: 8),
                    _statChip(Icons.score_outlined, '총 ${template.totalScore}점'),
                    const SizedBox(width: 8),
                    _statChip(
                      Icons.comment_outlined,
                      '코멘트 ${template.questions.where((q) => q.hasComment).length}개',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 문항 미리보기
                ...template.questions.take(5).map((q) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${q.orderIndex + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(q.title, style: AppStyles.bodyMedium)),
                      Text(
                        '${q.maxScore}점',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                )),
                if (template.questions.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... 외 ${template.questions.length - 5}개 항목',
                      style: AppStyles.caption,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppStyles.labelMedium),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, String action) async {
    if (action == 'edit') {
      rootNavigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => TemplateEditScreen(template: template)),
      );
    } else if (action == 'delete') {
      final ok = await showConfirmDialog(
        context,
        title: '템플릿 삭제',
        content: '\'${template.name}\' 템플릿을 삭제하시겠습니까?',
        confirmText: '삭제',
        isDestructive: true,
      );
      if (ok == true && context.mounted) {
        await context.read<AppProvider>().deleteTemplate(template.id);
        showSuccess(context, '템플릿이 삭제되었습니다.');
      }
    }
  }
}

// ── 템플릿 편집 화면 ───────────────────────────────────────────
class TemplateEditScreen extends StatefulWidget {
  final EvalTemplate? template;
  const TemplateEditScreen({super.key, this.template});

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<Question> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      final t = widget.template!;
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description;
      _questions = t.questions.map((q) => q.copyWith()).toList();
    } else {
      // 기본 10문항
      _questions = List.generate(
        10,
        (i) => Question(
          id: _uuid.v4(),
          title: _defaultTitles[i],
          maxScore: 10,
          orderIndex: i,
          hasComment: i == 9,
        ),
      );
    }
  }

  static const _defaultTitles = [
    '제품 이해도', '시장 적합성', '금융기관 고객 적합성', '수익성/사업성',
    '리스크 관리 가능성', '규제/컴플라이언스 적합성', '운영 안정성',
    '차별성', '확장 가능성', '종합 평가',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.fold(0, (sum, q) => sum + q.maxScore);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.template != null ? '템플릿 수정' : '새 템플릿 생성'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 기본 정보
              Container(
                padding: const EdgeInsets.all(20),
                color: AppTheme.surface,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: '템플릿 이름 *'),
                      validator: (v) => v?.trim().isEmpty == true ? '이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '총 ${_questions.length}개 항목 · 합계 $total점',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 문항 목록
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length + 1,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex >= _questions.length || newIndex > _questions.length) return;
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _questions.removeAt(oldIndex);
                      _questions.insert(newIndex, item);
                      for (int i = 0; i < _questions.length; i++) {
                        _questions[i] = _questions[i].copyWith(orderIndex: i);
                      }
                    });
                  },
                  itemBuilder: (ctx, i) {
                    if (i == _questions.length) {
                      return Padding(
                        key: const ValueKey('add_btn'),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: OutlinedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('항목 추가'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      );
                    }
                    return _QuestionItem(
                      key: ValueKey(_questions[i].id),
                      question: _questions[i],
                      index: i,
                      onChanged: (q) => setState(() => _questions[i] = q),
                      onDelete: () => setState(() => _questions.removeAt(i)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _questions.add(Question(
        id: _uuid.v4(),
        title: '새 평가 항목',
        maxScore: 10,
        orderIndex: _questions.length,
      ));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      showError(context, '최소 1개 이상의 문항이 필요합니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      if (widget.template != null) {
        final t = widget.template!;
        t.name = _nameCtrl.text.trim();
        t.description = _descCtrl.text.trim();
        t.questions = _questions;
        await provider.updateTemplate(t);
        if (mounted) showSuccess(context, '템플릿이 수정되었습니다.');
      } else {
        await provider.createTemplate(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          questions: _questions,
        );
        if (mounted) showSuccess(context, '템플릿이 생성되었습니다.');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _QuestionItem extends StatelessWidget {
  final Question question;
  final int index;
  final ValueChanged<Question> onChanged;
  final VoidCallback onDelete;

  const _QuestionItem({
    super.key,
    required this.question,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: question.title,
                    decoration: const InputDecoration(
                      hintText: '항목 이름',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: AppStyles.bodyMedium,
                    onChanged: (v) => onChanged(question.copyWith(title: v)),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    initialValue: question.maxScore.toString(),
                    decoration: const InputDecoration(
                      hintText: '배점',
                      suffixText: '점',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) {
                      final score = int.tryParse(v);
                      if (score != null) onChanged(question.copyWith(maxScore: score));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                  onPressed: onDelete,
                  tooltip: '삭제',
                ),
                const Icon(Icons.drag_handle, size: 18, color: AppTheme.textHint),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 32),
                _toggleChip(
                  label: '코멘트',
                  icon: Icons.comment_outlined,
                  value: question.hasComment,
                  onChanged: (v) => onChanged(question.copyWith(hasComment: v)),
                ),
                const SizedBox(width: 8),
                _toggleChip(
                  label: '필수',
                  icon: Icons.check_circle_outline,
                  value: question.isRequired,
                  onChanged: (v) => onChanged(question.copyWith(isRequired: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryLight : AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: value ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: value ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
