import '../models/project_suggestion.dart';
import '../models/published_schedule.dart';
import '../models/review_attendance.dart';
import '../models/review_round.dart';
import '../models/review_session.dart';
import '../models/semester.dart';

/// Dữ liệu mẫu để test UI khi không có/không kết nối được backend.
abstract final class MockSampleData {
  static const demoToken = 'demo-mock-token';

  /// Tài khoản test từ backend (sau seed workflow).
  static const backendTestAccounts = [
    ('minhnd.gv24001@fpt.edu.vn', 'Test@123456', 'GV24001 — Nguyễn Đức Minh'),
    ('hapt.gv24002@fpt.edu.vn', 'Test@123456', 'GV24002 — Phạm Thu Hà'),
    ('namlh.gv24003@fpt.edu.vn', 'Test@123456', 'GV24003 — Lê Hoàng Nam'),
    ('pdt.dieuphoi@fpt.edu.vn', 'Test@123456', 'Phòng Đào tạo'),
    ('demo.lecturer1', 'Demo@2026', 'Tài khoản demo dataset'),
    ('Admin@gmail.com', '12345', 'Training Dept (seed mặc định)'),
  ];

  static List<Semester> get semesters => const [
    Semester(
      id: 1,
      code: 'SP26',
      name: 'Học kỳ Spring 2026',
      academicYear: '2025-2026',
      isActive: true,
    ),
  ];

  static List<ReviewRound> get reviewRounds {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final saturday = monday.add(const Duration(days: 5));
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

    return [
      ReviewRound(
        id: 4,
        semesterId: 1,
        type: 'Review2',
        status: 'Open',
        registrationEndDate: date(saturday),
        weekStartDate: date(monday),
        weekEndDate: date(saturday),
        registrationCount: 7,
      ),
    ];
  }

  static Set<String> get preselectedSlotKeys => {
    '1-1',
    '1-3',
    '2-2',
    '3-4',
    '4-5',
    '5-1',
  };

  static Map<String, int> get studentOccupancyMap => {
    '1-1': 2,
    '1-2': 3,
    '1-3': 1,
    '2-4': 3,
    '3-2': 1,
    '4-5': 2,
  };

  static Map<String, int> get lecturerRegistrationCounts => {
    '1-1': 2,
    '1-3': 1,
    '2-2': 3,
    '4-3': 4,
    '5-1': 1,
  };

  static StudentPublishedSchedule get studentSchedule =>
      const StudentPublishedSchedule(
        groupCode: 'G-SWD-01',
        groupName: 'Hệ thống đăng ký & xếp lịch review capstone',
        dayLabel: 'Thứ 4, 02/07/2026',
        slotLabel: 'Slot 3 · 12:30 – 14:30',
        room: 'P.301 – Tòa Alpha',
        supervisorName: 'TS. Nguyễn Văn An',
        reviewers: [
          ScheduleReviewer(
            name: 'ThS. Trần Minh Khoa',
            department: 'Khoa CNTT',
          ),
          ScheduleReviewer(name: 'ThS. Lê Thu Hà', department: 'Khoa CNTT'),
        ],
      );

  static List<ReviewSession> get lecturerSessions => [
    ReviewSession(
      sessionId: 101,
      submissionId: 501,
      code: 'RV-2026-W26-01',
      type: 'Review2',
      sessionStatus: 'Published',
      groupCode: 'G-SWD-01',
      sessionDate: DateTime.now(),
      slot: 3,
      room: 'P.301',
      submissionStatus: 'Draft',
    ),
    ReviewSession(
      sessionId: 102,
      submissionId: 502,
      code: 'RV-2026-W26-02',
      type: 'Review2',
      sessionStatus: 'Published',
      groupCode: 'G-SWD-07',
      sessionDate: DateTime.now(),
      slot: 3,
      room: 'P.301',
      submissionStatus: 'Draft',
    ),
    ReviewSession(
      sessionId: 103,
      submissionId: 503,
      code: 'RV-2026-W26-03',
      type: 'Review2',
      sessionStatus: 'Published',
      groupCode: 'G-SWD-12',
      sessionDate: DateTime.now().subtract(const Duration(days: 1)),
      slot: 3,
      room: 'P.301',
      submissionStatus: 'Submitted',
    ),
    ReviewSession(
      sessionId: 201,
      submissionId: 601,
      code: 'RV-2026-W26-04',
      type: 'Review3',
      sessionStatus: 'Published',
      groupCode: 'G-SWD-03',
      sessionDate: DateTime.now().add(const Duration(days: 1)),
      slot: 1,
      room: 'P.205',
      submissionStatus: 'Draft',
    ),
  ];

  static ReviewAttendanceList get attendanceList => ReviewAttendanceList(
    sessionId: 101,
    sessionCode: 'RV-2026-W26-01',
    groupId: 1,
    groupCode: 'G-SWD-01',
    sessionDate: DateTime(2026, 7, 2, 13, 30),
    slot: 3,
    room: 'P.301',
    students: const [
      AttendanceStudent(
        studentId: 1,
        studentCode: 'SE194001',
        fullName: 'Nguyễn Văn A',
        isPresent: true,
      ),
      AttendanceStudent(
        studentId: 2,
        studentCode: 'SE194002',
        fullName: 'Trần Thị B',
        isPresent: true,
      ),
      AttendanceStudent(
        studentId: 3,
        studentCode: 'SE194003',
        fullName: 'Lê Văn C',
        isPresent: true,
      ),
      AttendanceStudent(
        studentId: 4,
        studentCode: 'SE194004',
        fullName: 'Phạm Thị D',
        isPresent: null,
      ),
    ],
  );

  static const aiSuggestion = ProjectSuggestion(
    contentSummary: 'Đồ án xây dựng app mobile đăng ký slot review capstone.',
    strengthsSummary: 'UI rõ ràng, tích hợp API JWT.',
    improvementSummary: 'Test coverage và xử lý offline.',
  );
}
