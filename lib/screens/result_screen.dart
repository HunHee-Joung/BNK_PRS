// ============================================================
// 집계 결과 화면
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class ResultScreen extends StatefulWidget {
  final EvalSession session;
  const ResultScreen({super.key, required this.session});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AggregateResult? _result;
  EvalTemplate? _template;
  bool _isLoading = true;

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
      final result = await provider.getAggregateResult(widget.session);
      final template = await provider.getTemplate(widget.session.templateId);
      if (mounted) {
        setState(() {
          _result = result;
          _template = template;
        });
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
        title: const Text('집계 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 20),
              tooltip: 'CSV 다운로드',
              onPressed: _result != null ? () => _downloadCsv(context) : null,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '요약'),
            Tab(text: '항목별 점수'),
            Tab(text: '평가자별'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: '집계 결과가 없습니다',
                  subtitle: '평가가 제출되면 결과가 표시됩니다.',
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildQuestionTab(),
                    _buildEvaluatorTab(),
                  ],
                ),
    );
  }

  // ── 요약 탭 ────────────────────────────────────────────────
  Widget _buildSummaryTab() {
    final r = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(widget.session.title, style: AppStyles.headlineSmall)),
                    StatusBadge(widget.session.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '제품: ${widget.session.productName} · 발표자: ${widget.session.presenterName}',
                  style: AppStyles.bodySmall,
                ),
                Text(
                  '일시: ${Formatters.dateTimeKr(widget.session.scheduledAt)}',
                  style: AppStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              InfoCard(
                label: '평균 총점',
                value: r.averageTotal.toStringAsFixed(1),
                sublabel: '/ ${_template?.totalScore ?? 100}점',
                icon: Icons.score_outlined,
                color: AppTheme.primary,
              ),
              InfoCard(
                label: '제출률',
                value: Formatters.percent(r.submissionRate),
                sublabel: '${r.submittedCount} / ${r.totalEvaluators}명',
                icon: Icons.how_to_vote_outlined,
                color: AppTheme.success,
              ),
              InfoCard(
                label: '최고점',
                value: '${r.maxTotal}점',
                icon: Icons.arrow_upward_outlined,
                color: AppTheme.info,
              ),
              InfoCard(
                label: '최저점',
                value: '${r.minTotal}점',
                icon: Icons.arrow_downward_outlined,
                color: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('제출 현황', style: AppStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              if (r.submittedCount > 0)
                                PieChartSectionData(
                                  value: r.submittedCount.toDouble(),
                                  color: AppTheme.success,
                                  title: '${r.submittedCount}명',
                                  radius: 64,
                                  titleStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                                  ),
                                ),
                              if (r.totalEvaluators - r.submittedCount > 0)
                                PieChartSectionData(
                                  value: (r.totalEvaluators - r.submittedCount).toDouble(),
                                  color: AppTheme.divider,
                                  title: '${r.totalEvaluators - r.submittedCount}명',
                                  radius: 64,
                                  titleStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                            centerSpaceRadius: 32,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem(AppTheme.success, '제출 완료', '${r.submittedCount}명'),
                          const SizedBox(height: 12),
                          _legendItem(
                            AppTheme.divider,
                            '미제출',
                            '${r.totalEvaluators - r.submittedCount}명',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 항목별 점수 탭 ─────────────────────────────────────────
  Widget _buildQuestionTab() {
    if (_template == null || _result == null) return const SizedBox();
    final r = _result!;
    final questions = _template!.questions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('항목별 평균 점수', style: AppStyles.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: questions.isNotEmpty
                          ? questions.map((q) => q.maxScore.toDouble()).reduce((a, b) => a > b ? a : b)
                          : 10,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final q = questions[group.x.toInt()];
                            final stat = r.questionStats[q.id];
                            return BarTooltipItem(
                              '${q.title}\n${stat?.average.toStringAsFixed(1) ?? 0}점',
                              const TextStyle(color: Colors.white, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: AppStyles.caption),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= questions.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${i + 1}', style: AppStyles.caption),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: AppTheme.divider, strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: questions.asMap().entries.map((e) {
                        final stat = r.questionStats[e.value.id];
                        final avg = stat?.average ?? 0;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: avg,
                              color: AppTheme.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: e.value.maxScore.toDouble(),
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(bottom: BorderSide(color: AppTheme.divider)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 28, child: Text('#', style: AppStyles.labelMedium)),
                      SizedBox(width: 8),
                      Expanded(child: Text('항목', style: AppStyles.labelMedium)),
                      SizedBox(width: 56, child: Text('평균', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                      SizedBox(width: 56, child: Text('최고', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                      SizedBox(width: 56, child: Text('최저', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                      SizedBox(width: 56, child: Text('편차', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                ...questions.asMap().entries.map((e) {
                  final q = e.value;
                  final stat = r.questionStats[q.id];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.divider)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(q.title, style: AppStyles.bodyMedium)),
                            SizedBox(
                              width: 56,
                              child: Text(
                                stat?.average.toStringAsFixed(1) ?? '-',
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text(
                                stat?.max.toString() ?? '-',
                                style: const TextStyle(fontSize: 13, color: AppTheme.success),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text(
                                stat?.min.toString() ?? '-',
                                style: const TextStyle(fontSize: 13, color: AppTheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text(
                                stat?.stdDev.toStringAsFixed(2) ?? '-',
                                style: AppStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ScoreGaugeBar(
                          score: stat?.average ?? 0,
                          maxScore: q.maxScore.toDouble(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 평가자별 탭 ────────────────────────────────────────────
  Widget _buildEvaluatorTab() {
    if (_result == null) return const SizedBox();
    final results = _result!.evaluatorResults;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: AppTheme.divider)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 36, child: Text('순위', style: AppStyles.labelMedium)),
                  Expanded(child: Text('평가자', style: AppStyles.labelMedium)),
                  SizedBox(width: 80, child: Text('총점', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('상태', style: AppStyles.labelMedium, textAlign: TextAlign.center)),
                ],
              ),
            ),
            ...results.asMap().entries.map((e) {
              final rank = e.key + 1;
              final res = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.divider)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: rank <= 3
                          ? _rankBadge(rank)
                          : Text('$rank', style: AppStyles.bodySmall, textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(res.evaluatorName, style: AppStyles.bodyMedium),
                          Text(res.department, style: AppStyles.caption),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        res.isSubmitted ? '${res.totalScore}점' : '-',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: res.isSubmitted ? AppTheme.primary : AppTheme.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: res.isSubmitted
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.divider,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            res.isSubmitted ? '제출' : '미제출',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: res.isSubmitted ? AppTheme.success : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    return Container(
      width: 28, height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors[rank - 1], shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
      ),
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

  // ── CSV 다운로드 (웹 전용) ─────────────────────────────────
  void _downloadCsv(BuildContext context) {
    if (_result == null || _template == null) return;
    final r = _result!;
    final questions = _template!.questions;

    final header = ['순위', '평가자', '부서', '총점', ...questions.map((q) => q.title), '제출 여부'];
    final rows = <List<dynamic>>[header];

    int rank = 1;
    for (final ev in r.evaluatorResults) {
      final row = <dynamic>[
        ev.isSubmitted ? rank : '-',
        ev.evaluatorName,
        ev.department,
        ev.isSubmitted ? ev.totalScore : '-',
        ...questions.map((q) => ev.scoresByQuestion[q.id] ?? '-'),
        ev.isSubmitted ? '제출' : '미제출',
      ];
      if (ev.isSubmitted) rank++;
      rows.add(row);
    }

    rows.add([]);
    rows.add(['항목별 통계', '평균', '최고', '최저', '표준편차']);
    for (final q in questions) {
      final stat = r.questionStats[q.id];
      rows.add([
        q.title,
        stat?.average.toStringAsFixed(1) ?? '-',
        stat?.max ?? '-',
        stat?.min ?? '-',
        stat?.stdDev.toStringAsFixed(2) ?? '-',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // 웹 다운로드
    if (kIsWeb) {
      final blob = html.Blob([csv], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '${widget.session.title}_평가결과.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    if (context.mounted) {
      showSuccess(context, 'CSV 파일이 다운로드되었습니다.');
    }
  }
}
