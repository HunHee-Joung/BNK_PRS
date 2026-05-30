// ============================================================
// 메인 셸 - 사이드 네비게이션 + 탭별 독립 Navigator
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'session_list_screen.dart';
import 'template_screen.dart';
import 'evaluator_list_screen.dart';
import 'audit_log_screen.dart';
import 'login_screen.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // 탭별 GlobalKey - 각 탭이 독립적인 Navigator를 가짐
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final _navItems = const [
    _NavItem(icon: Icons.event_note_outlined, activeIcon: Icons.event_note, label: '설명회 관리'),
    _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: '평가 템플릿'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: '평가자 관리'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: '감사 로그'),
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return const SessionListScreen();
      case 1: return const TemplateScreen();
      case 2: return const EvaluatorListScreen();
      case 3: return const AuditLogScreen();
      default: return const SessionListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navState = _navigatorKeys[_selectedIndex].currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        }
      },
      child: Scaffold(
        body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  // ── 와이드 레이아웃 (태블릿/데스크탑) ──────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSideRail(),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _buildTabNavigator(_selectedIndex),
        ),
      ],
    );
  }

  // ── 좁은 레이아웃 (모바일) ─────────────────────────────────
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(child: _buildTabNavigator(_selectedIndex)),
        _buildBottomNav(),
      ],
    );
  }

  // ── 탭별 독립 Navigator ────────────────────────────────────
  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => _buildScreen(index),
      ),
    );
  }

  Widget _buildSideRail() {
    return Consumer<AppProvider>(
      builder: (_, provider, __) => Container(
        width: 220,
        color: AppTheme.surface,
        child: Column(
          children: [
            // 로고 영역
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assessment, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '평가 시스템',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '관리자 포털',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 네비게이션 항목
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (ctx, i) {
                  final item = _navItems[i];
                  final isSelected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 20,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.primaryLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onTap: () => setState(() => _selectedIndex = i),
                      dense: true,
                    ),
                  );
                },
              ),
            ),

            // 사용자 정보
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      provider.currentAdmin?.name.substring(0, 1) ?? 'A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.currentAdmin?.name ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          provider.currentAdmin?.role.label ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 18, color: AppTheme.textSecondary),
                    tooltip: '로그아웃',
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primaryLight,
        height: 64,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon, size: 22),
                  selectedIcon: Icon(item.activeIcon, size: 22, color: AppTheme.primary),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: '로그아웃',
      content: '로그아웃 하시겠습니까?\n접속 기록이 저장됩니다.',
      confirmText: '로그아웃',
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().logout();
      if (mounted) {
        rootNavigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
