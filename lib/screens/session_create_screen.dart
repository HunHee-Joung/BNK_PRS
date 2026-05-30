// ============================================================
// 설명회 생성 화면
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class SessionCreateScreen extends StatefulWidget {
  final EvalSession? editSession;
  const SessionCreateScreen({super.key, this.editSession});

  @override
  State<SessionCreateScreen> createState() => _SessionCreateScreenState();
}

class _SessionCreateScreenState extends State<SessionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _presenterCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  String? _selectedTemplateId;
  List<String> _selectedEvaluatorIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editSession != null) {
      final s = widget.editSession!;
      _titleCtrl.text = s.title;
      _productCtrl.text = s.productName;
      _presenterCtrl.text = s.presenterName;
      _companyCtrl.text = s.presenterCompany;
      _notesCtrl.text = s.notes;
      _scheduledAt = s.scheduledAt;
      _selectedTemplateId = s.templateId;
      _selectedEvaluatorIds = List.from(s.evaluatorIds);
    } else {
      // 기본 템플릿 자동 선택
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final templates = context.read<AppProvider>().templates;
        if (templates.isNotEmpty) {
          final def = templates.firstWhere(
            (t) => t.isDefault,
            orElse: () => templates.first,
          );
          setState(() => _selectedTemplateId = def.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _productCtrl.dispose();
    _presenterCtrl.dispose();
    _companyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editSession != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? '설명회 수정' : '새 설명회 생성'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: Text(isEdit ? '저장' : '생성'),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: '저장 중...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('기본 정보', [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '설명회 제목 *',
                      hintText: '예: 2024년 4분기 핀테크 제품 설명회',
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? '제목을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _productCtrl,
                    decoration: const InputDecoration(
                      labelText: '제품명 *',
                      hintText: '예: 디지털 자산 관리 플랫폼 v2.0',
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? '제품명을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _presenterCtrl,
                          decoration: const InputDecoration(
                            labelText: '발표자 *',
                            hintText: '홍길동',
                          ),
                          validator: (v) => v?.trim().isEmpty == true ? '발표자를 입력하세요' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _companyCtrl,
                          decoration: const InputDecoration(
                            labelText: '발표사',
                            hintText: '(주)핀테크솔루션',
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSection('일정', [
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('설명회 일시', style: AppStyles.labelMedium),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('yyyy년 MM월 dd일 (E) HH:mm', 'ko').format(_scheduledAt),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildTemplateSection(),
                const SizedBox(height: 20),
                _buildEvaluatorSection(),
                const SizedBox(height: 20),
                _buildSection('기타', [
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '메모 (선택)',
                      hintText: '관리자 내부 메모...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.labelLarge.copyWith(color: AppTheme.primary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSection() {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final templates = provider.templates;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('평가 템플릿', style: AppStyles.labelLarge.copyWith(color: AppTheme.primary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: templates.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('등록된 템플릿이 없습니다. 먼저 템플릿을 생성해주세요.'),
                    )
                  : Column(
                      children: templates.map((t) {
                        final isSelected = _selectedTemplateId == t.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedTemplateId = t.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(t.name, style: AppStyles.bodyMedium),
                                          if (t.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryLight,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '기본',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        '${t.questions.length}개 항목 · 총 ${t.totalScore}점',
                                        style: AppStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEvaluatorSection() {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final evaluators = provider.evaluators.where((e) => e.isActive).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('평가자 등록', style: AppStyles.labelLarge.copyWith(color: AppTheme.primary)),
                const SizedBox(width: 8),
                Text(
                  '${_selectedEvaluatorIds.length}명 선택',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() =>
                              _selectedEvaluatorIds = evaluators.map((e) => e.id).toList()),
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('전체 선택'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedEvaluatorIds = []),
                          icon: const Icon(Icons.deselect, size: 16),
                          label: const Text('전체 해제'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (evaluators.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('등록된 평가자가 없습니다. 먼저 평가자를 등록해주세요.'),
                    )
                  else
                    ...evaluators.map((e) {
                      final checked = _selectedEvaluatorIds.contains(e.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedEvaluatorIds.add(e.id);
                            } else {
                              _selectedEvaluatorIds.remove(e.id);
                            }
                          });
                        },
                        title: Text(e.name, style: AppStyles.bodyMedium),
                        subtitle: Text('${e.department} · ${e.organization}', style: AppStyles.caption),
                        activeColor: AppTheme.primary,
                        dense: true,
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            e.name.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplateId == null) {
      showError(context, '평가 템플릿을 선택해주세요.');
      return;
    }
    if (_selectedEvaluatorIds.isEmpty) {
      showError(context, '평가자를 최소 1명 이상 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      if (widget.editSession != null) {
        final s = widget.editSession!;
        s.title = _titleCtrl.text.trim();
        s.productName = _productCtrl.text.trim();
        s.presenterName = _presenterCtrl.text.trim();
        s.presenterCompany = _companyCtrl.text.trim();
        s.scheduledAt = _scheduledAt;
        s.templateId = _selectedTemplateId!;
        s.evaluatorIds = _selectedEvaluatorIds;
        s.notes = _notesCtrl.text.trim();
        await provider.updateSession(s);
        if (mounted) showSuccess(context, '설명회가 수정되었습니다.');
      } else {
        await provider.createSession(
          title: _titleCtrl.text.trim(),
          productName: _productCtrl.text.trim(),
          presenterName: _presenterCtrl.text.trim(),
          presenterCompany: _companyCtrl.text.trim(),
          scheduledAt: _scheduledAt,
          templateId: _selectedTemplateId!,
          evaluatorIds: _selectedEvaluatorIds,
          notes: _notesCtrl.text.trim(),
        );
        if (mounted) showSuccess(context, '설명회가 생성되었습니다.');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, '오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
