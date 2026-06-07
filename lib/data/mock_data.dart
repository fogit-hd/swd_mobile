import '../models/schedule_item.dart';

class MockData {
  static List<ScheduleItem> initialSchedule() => [
        const ScheduleItem(
          sessionId: 1,
          groupId: 101,
          groupName: 'Nhóm 01',
          projectTitle: 'Hệ thống quản lý thư viện thông minh',
          timeSlot: '08:00 • Ca 1',
          room: 'Phòng A101',
          status: SessionStatus.completed,
          councilCode: 'HD-01',
        ),
        const ScheduleItem(
          sessionId: 2,
          groupId: 102,
          groupName: 'Nhóm 02',
          projectTitle: 'Ứng dụng học ngoại ngữ AI',
          timeSlot: '08:30 • Ca 2',
          room: 'Phòng A101',
          status: SessionStatus.inProgress,
          councilCode: 'HD-01',
        ),
        const ScheduleItem(
          sessionId: 3,
          groupId: 103,
          groupName: 'Nhóm 03',
          projectTitle: 'Nền tảng thương mại điện tử B2B',
          timeSlot: '09:00 • Ca 3',
          room: 'Phòng A101',
          status: SessionStatus.waiting,
          councilCode: 'HD-01',
        ),
        const ScheduleItem(
          sessionId: 4,
          groupId: 104,
          groupName: 'Nhóm 04',
          projectTitle: 'Hệ thống giám sát IoT nông nghiệp',
          timeSlot: '09:30 • Ca 4',
          room: 'Phòng A101',
          status: SessionStatus.waiting,
          councilCode: 'HD-01',
        ),
      ];

  /// Tài khoản mock sẵn có (mật khẩu chung):
  /// App chỉ có 2 role: panel, moderator
  static const demoPassword = '123456';
}
