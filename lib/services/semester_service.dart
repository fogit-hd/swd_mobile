import 'dart:convert';

import '../models/capstone_group.dart';
import '../models/semester.dart';
import '../utils/week_utils.dart';
import 'api_client.dart';

class SemesterService {
  SemesterService(this._client);

  final ApiClient _client;

  Future<List<Semester>> fetchSemesters({int pageSize = 100}) async {
    final response = await _client.get(
      '/api/semesters',
      query: {
        'page': '1',
        'pageSize': pageSize.toString(),
      },
    );
    _client.throwIfFailed(response, 'Tải học kỳ');

    final decoded = jsonDecode(response.body);
    // BE trả PagedResult { items, page, pageSize, totalCount }
    final List<dynamic> list;
    if (decoded is Map<String, dynamic>) {
      list = decoded['items'] as List<dynamic>? ?? const [];
    } else if (decoded is List<dynamic>) {
      list = decoded;
    } else {
      list = const [];
    }

    return list
        .map((e) => Semester.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Semester?> resolveActiveSemester({String? date}) async {
    final response = await _client.get(
      '/api/semesters/resolve',
      query: {'date': date ?? weekStartOf(DateTime.now())},
    );
    if (response.statusCode == 404) return null;
    _client.throwIfFailed(response, 'Xác định học kỳ');

    return Semester.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Semester> getActiveSemester() async {
    final resolved = await resolveActiveSemester();
    if (resolved != null) return resolved;

    final semesters = await fetchSemesters();
    if (semesters.isEmpty) {
      throw ApiException('Không tìm thấy học kỳ nào.');
    }

    return semesters.firstWhere(
      (s) => s.isActive,
      orElse: () => semesters.first,
    );
  }

  Future<List<CapstoneGroup>> fetchGroups(int semesterId) async {
    final response = await _client.get('/api/semesters/$semesterId/groups');
    _client.throwIfFailed(response, 'Tải danh sách nhóm');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CapstoneGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy thành viên nhóm — quét học kỳ active rồi các kỳ khác nếu cần.
  Future<List<CapstoneGroupMember>> fetchGroupMembers({
    required int groupId,
  }) async {
    final semester = await getActiveSemester();
    final groups = await fetchGroups(semester.id);
    for (final group in groups) {
      if (group.id == groupId) return group.members;
    }
    final semesters = await fetchSemesters();
    for (final s in semesters) {
      if (s.id == semester.id) continue;
      final more = await fetchGroups(s.id);
      for (final group in more) {
        if (group.id == groupId) return group.members;
      }
    }
    return const [];
  }
}
