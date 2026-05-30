// ============================================================
// 금융기관용 제품 설명회 평가·집계 시스템
// Presentation Evaluator v1.0 (MVP)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';

// 전역 Navigator Key - rootNavigator 접근용
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 한국어 로케일 데이터 초기화 (DateFormat 'ko' 사용 시 필수)
  await initializeDateFormatting('ko_KR', null);
  await StorageService.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const PresentationEvaluatorApp(),
    ),
  );
}

class PresentationEvaluatorApp extends StatelessWidget {
  const PresentationEvaluatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '제품 설명회 평가 시스템',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.themeData,
      // 한국어 로케일 지원 (DatePicker, TimePicker 한글화)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      home: const LoginScreen(),
    );
  }
}
