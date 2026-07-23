/// Dịch giá trị API (tiếng Anh) sang nhãn hiển thị tiếng Việt.
/// Giữ nguyên raw khi so sánh logic; chỉ dùng khi render UI.
abstract final class DisplayLabels {
  static String reviewType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Đợt review';
    switch (raw.trim().toLowerCase()) {
      case 'review1':
      case 'review 1':
        return 'Review đợt 1';
      case 'review2':
      case 'review 2':
        return 'Review đợt 2';
      case 'review3':
      case 'review 3':
        return 'Review đợt 3';
      case 'review':
        return 'Review';
      default:
        return raw;
    }
  }

  static String roundStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    switch (raw.trim().toLowerCase()) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã đóng';
      case 'draft':
        return 'Nháp';
      case 'scheduled':
        return 'Đã lên lịch';
      default:
        return raw;
    }
  }

  static String sessionStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    switch (raw.trim().toLowerCase()) {
      case 'published':
        return 'Đã công bố';
      case 'draft':
        return 'Nháp';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'completed':
        return 'Đã hoàn tất';
      case 'inprogress':
      case 'in_progress':
        return 'Đang diễn ra';
      default:
        return raw;
    }
  }

  static String submissionStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    switch (raw.trim().toLowerCase()) {
      case 'draft':
        return 'Đang soạn';
      case 'submitted':
        return 'Đã gửi';
      default:
        return raw;
    }
  }

  /// Ưu tiên trạng thái bài chấm, sau đó trạng thái phiên.
  static String reviewWorkflowStatus({
    String? submissionStatus,
    String? sessionStatus,
  }) {
    final sub = submissionStatus?.trim().toLowerCase();
    if (sub == 'submitted') return 'Đã gửi';
    if (sub == 'draft') return 'Đang soạn';
    final session = DisplayLabels.sessionStatus(sessionStatus);
    if (session != '—') return session;
    return submissionStatusLabel(submissionStatus);
  }

  static String submissionStatusLabel(String? raw) => submissionStatus(raw);

  static String groupStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    switch (raw.trim().toLowerCase()) {
      case 'active':
        return 'Đang hoạt động';
      case 'inactive':
        return 'Ngưng';
      case 'completed':
        return 'Đã hoàn thành';
      case 'pending':
        return 'Chờ xử lý';
      default:
        return raw;
    }
  }

  static String notificationType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Thông báo';
    switch (raw.trim().toLowerCase()) {
      case 'docstatuschange':
        return 'Tài liệu thay đổi trạng thái';
      case 'newcomment':
        return 'Bình luận mới';
      case 'reportdone':
        return 'Báo cáo đã xong';
      case 'scorelocked':
        return 'Điểm đã khóa';
      case 'reviewschedulepublished':
        return 'Lịch review đã công bố';
      default:
        return raw;
    }
  }

  static String documentType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Tài liệu';
    switch (raw.trim().toLowerCase()) {
      case 'proposal':
        return 'Đề xuất (Proposal)';
      case 'progress':
        return 'Tiến độ (Progress)';
      case 'final':
        return 'Báo cáo cuối (Final)';
      default:
        return raw;
    }
  }

  static String documentStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    switch (raw.trim().toLowerCase()) {
      case 'submitted':
        return 'Đã nộp';
      case 'evaluating':
        return 'Đang đánh giá';
      case 'needsrevision':
      case 'needs_revision':
        return 'Cần chỉnh sửa';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return raw;
    }
  }

  static String orDash(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return '—';
    return v;
  }
}
