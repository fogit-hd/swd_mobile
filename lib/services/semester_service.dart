import 'dart:convert';

import '../models/create_semester.dart';
import '../models/semester.dart';
import '../utils/week_utils.dart';
import 'api_client.dart';

class SemesterService {
  SemesterService(this._client);

  final ApiClient _client;

  Future<List<Semester>> fetchSemesters() async {
    final response = await _client.get('/api/semesters');
    _client.throwIfFailed(response, 'Tải học kỳ');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Semester.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Semester> createSemester(CreateSemesterRequest request) async {
    final response = await _client.post('/api/semesters', body: request.toJson());
    _client.throwIfFailed(response, 'Tạo học kỳ');

    return Semester.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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
}
