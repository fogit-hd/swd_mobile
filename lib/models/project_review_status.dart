import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Trạng thái đồ án trong buổi review — màu pastel theo spec giáo dục.
enum ProjectReviewStatus {
  notStarted('Chưa chấm', AppTheme.statusPendingBg, AppTheme.statusPendingFg),
  inProgress('Đang chấm', AppTheme.statusActiveBg, AppTheme.statusActiveFg),
  completed('Đã xong', AppTheme.statusDoneBg, AppTheme.statusDoneFg);

  const ProjectReviewStatus(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;
}
