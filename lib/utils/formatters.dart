// ============================================================
// 공통 유틸리티 - 날짜 포매터, 상태 변환 등
// ============================================================

import 'package:intl/intl.dart';
import '../models/app_models.dart';
import 'app_theme.dart';
import 'package:flutter/material.dart';

class Formatters {
  static final _dateTime = DateFormat('yyyy.MM.dd HH:mm');
  static final _date = DateFormat('yyyy.MM.dd');
  static final _time = DateFormat('HH:mm');
  static final _dateKr = DateFormat('yyyy년 MM월 dd일');
  static final _dateTimeKr = DateFormat('yyyy년 MM월 dd일 HH:mm');

  static String dateTime(DateTime dt) => _dateTime.format(dt);
  static String date(DateTime dt) => _date.format(dt);
  static String time(DateTime dt) => _time.format(dt);
  static String dateKr(DateTime dt) => _dateKr.format(dt);
  static String dateTimeKr(DateTime dt) => _dateTimeKr.format(dt);

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return date(dt);
  }

  static String percent(double v) => '${(v * 100).toStringAsFixed(1)}%';
  static String score(double v) => v.toStringAsFixed(1);
  static String scoreInt(int v) => v.toString();
}

extension SessionStatusEx on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.scheduled: return '진행 예정';
      case SessionStatus.ongoing: return '진행 중';
      case SessionStatus.closed: return '종료';
    }
  }

  Color get color {
    switch (this) {
      case SessionStatus.scheduled: return AppTheme.statusScheduled;
      case SessionStatus.ongoing: return AppTheme.statusOngoing;
      case SessionStatus.closed: return AppTheme.statusClosed;
    }
  }

  IconData get icon {
    switch (this) {
      case SessionStatus.scheduled: return Icons.schedule_outlined;
      case SessionStatus.ongoing: return Icons.play_circle_outline;
      case SessionStatus.closed: return Icons.check_circle_outline;
    }
  }
}

extension UserRoleEx on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin: return '관리자';
      case UserRole.superAdmin: return '슈퍼관리자';
      case UserRole.auditor: return '감사자';
    }
  }
}

extension AuditActionEx on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.login: return '로그인';
      case AuditAction.logout: return '로그아웃';
      case AuditAction.sessionCreate: return '설명회 생성';
      case AuditAction.sessionEdit: return '설명회 수정';
      case AuditAction.sessionClose: return '설명회 종료';
      case AuditAction.evaluatorRegister: return '평가자 등록';
      case AuditAction.evaluatorAuth: return '평가자 인증';
      case AuditAction.submissionCreate: return '평가 제출';
      case AuditAction.submissionReopen: return '재오픈';
      case AuditAction.resultView: return '결과 조회';
      case AuditAction.resultDownload: return '결과 다운로드';
      case AuditAction.templateCreate: return '템플릿 생성';
      case AuditAction.templateEdit: return '템플릿 수정';
    }
  }

  IconData get icon {
    switch (this) {
      case AuditAction.login: return Icons.login;
      case AuditAction.logout: return Icons.logout;
      case AuditAction.sessionCreate: return Icons.add_circle_outline;
      case AuditAction.sessionEdit: return Icons.edit_outlined;
      case AuditAction.sessionClose: return Icons.stop_circle_outlined;
      case AuditAction.evaluatorRegister: return Icons.person_add_outlined;
      case AuditAction.evaluatorAuth: return Icons.verified_user_outlined;
      case AuditAction.submissionCreate: return Icons.send_outlined;
      case AuditAction.submissionReopen: return Icons.refresh_outlined;
      case AuditAction.resultView: return Icons.bar_chart_outlined;
      case AuditAction.resultDownload: return Icons.download_outlined;
      case AuditAction.templateCreate: return Icons.description_outlined;
      case AuditAction.templateEdit: return Icons.edit_note_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AuditAction.login:
      case AuditAction.evaluatorAuth:
        return AppTheme.success;
      case AuditAction.logout:
        return AppTheme.textSecondary;
      case AuditAction.submissionCreate:
        return AppTheme.info;
      case AuditAction.sessionClose:
        return AppTheme.warning;
      case AuditAction.submissionReopen:
        return AppTheme.warning;
      case AuditAction.resultDownload:
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }
}
