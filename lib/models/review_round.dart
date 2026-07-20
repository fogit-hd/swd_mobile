import 'review_enums.dart';
import '../utils/display_labels.dart';

class ReviewRound {
  const ReviewRound({
    required this.id,
    required this.semesterId,
    this.type,
    this.status,
    this.weekStartDate,
    this.weekEndDate,
    this.openedAt,
    this.closedAt,
    this.registrationCount,
  });

  factory ReviewRound.fromJson(Map<String, dynamic> json) {
    return ReviewRound(
      id: json['id'] as int? ?? 0,
      semesterId: json['semesterId'] as int? ?? 0,
      type: json['type'] as String?,
      status: json['status'] as String?,
      weekStartDate: json['weekStartDate']?.toString(),
      weekEndDate: json['weekEndDate']?.toString(),
      openedAt: json['openedAt'] != null
          ? DateTime.tryParse(json['openedAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      registrationCount: json['registrationCount'] as int?,
    );
  }

  final int id;
  final int semesterId;
  final String? type;
  final String? status;
  final String? weekStartDate;
  final String? weekEndDate;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final int? registrationCount;

  bool get isOpen => status == 'Open';

  ReviewType? get reviewType => ReviewType.tryParse(type);

  String get statusLabel => DisplayLabels.roundStatus(status);

  String get typeLabel => DisplayLabels.reviewType(type);

  String get displayName {
    final week = weekStartDate ?? '—';
    return '$typeLabel · tuần $week';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReviewRound && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
