import 'package:flutter/material.dart';

/// Khoảng cách chuẩn theo Apple HIG — bội số của 4pt.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Vùng chạm tối thiểu 44×44 (Apple).
  static const double minTouchTarget = 44;

  static const pagePadding = EdgeInsets.all(md);
  static const cardPadding = EdgeInsets.all(md);
}
