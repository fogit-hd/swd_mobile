import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient(this._auth);

  final AuthService _auth;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_auth.accessToken != null)
      'Authorization': 'Bearer ${_auth.accessToken}',
  };

  Future<http.Response> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) => _send(
    () => http.post(
      _uri(path, query),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ),
  );

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) => _send(
    () => http.put(
      _uri(path, query),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ),
  );

  Future<http.Response> patch(String path, {Object? body}) => _send(
    () => http.patch(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ),
  );

  Future<http.Response> delete(String path, {Map<String, String>? query}) =>
      _send(() => http.delete(_uri(path, query), headers: _headers));

  Future<http.Response> postMultipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_auth.accessToken != null) {
      request.headers['Authorization'] = 'Bearer ${_auth.accessToken}';
    }
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);

    final streamed = await request.send();
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && await _tryRefresh()) {
      final retry = http.MultipartRequest('POST', _uri(path));
      retry.headers['Authorization'] = 'Bearer ${_auth.accessToken}';
      if (fields != null) retry.fields.addAll(fields);
      retry.files.addAll(files);
      final retryStream = await retry.send();
      response = await http.Response.fromStream(retryStream);
    }

    return response;
  }

  Future<List<int>> download(String path, {Map<String, String>? query}) async {
    final response = await get(path, query: query);
    throwIfFailed(response, 'Tải file');
    return response.bodyBytes;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await request();
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    try {
      await _auth.refreshAccessToken(notify: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  void throwIfFailed(http.Response response, String action) {
    if (response.statusCode >= 400) {
      String message = '$action thất bại (${response.statusCode})';
      if (response.statusCode == 403) {
        // Verify access-code đôi khi trả `Forbid()` không kèm body message.
        // Dùng message mặc định thân thiện để user hiểu nguyên nhân.
        message =
            'Bạn không có quyền truy cập buổi review này hoặc bạn chưa được phân công. (403)';
      }
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          // BE dùng ApiResponse { message, errors[] } hoặc { error }.
          final detail = body['message'] ?? body['error'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = localizeMessage(detail);
          } else {
            final errors = body['errors'];
            if (errors is List && errors.isNotEmpty) {
              final first = errors.first;
              if (first is Map && first['message'] is String) {
                message = localizeMessage(first['message'] as String);
              }
            }
          }
        }
      } catch (_) {}
      throw ApiException(
        message,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  static String localizeMessage(String raw) {
    switch (raw) {
      case 'No group assigned to this session.':
      case 'Phiên này có nhiều nhóm — cần truyền groupId để xem điểm danh.':
      case 'Buổi review này có nhiều nhóm. Vui lòng mở lại đúng nhóm từ lịch chấm.':
        return 'Buổi review này có nhiều nhóm. Vui lòng quay lại lịch chấm và chọn đúng nhóm cần điểm danh.';
      case 'Review session not found.':
      case 'Không tìm thấy phiên review.':
        return 'Không tìm thấy buổi review.';
      case 'The review session is not published.':
      case 'Phiên review chưa được công bố.':
        return 'Buổi review chưa được công bố.';
      case 'You cannot view this attendance.':
      case 'Bạn không có quyền xem điểm danh này.':
        return 'Bạn không có quyền xem điểm danh buổi này.';
      case 'Lecturer availability can only be changed while registration is Open.':
        return 'Chỉ đăng ký được khi đợt review đang mở.';
      case 'Lecturer availability can only be submitted while registration is Open.':
        return 'Chỉ gửi đăng ký được khi đợt review đang mở.';
      case 'Every checklist item and the reviewer comment are required before submission.':
        return 'Cần trả lời đủ checklist và ghi nhận xét chung trước khi gửi bài chấm.';
      case 'This review submission has already been submitted.':
        return 'Bài chấm này đã được gửi.';
      case 'Gemini is not configured. Set Gemini:ApiKey before using project suggestions.':
        return 'Máy chủ chưa cấu hình Gemini cho gợi ý AI.';
      case 'Gemini is temporarily unavailable. Please try again later.':
        return 'Gemini đang bận hoặc bị giới hạn tạm thời. '
            'Nếu vừa test Swagger, đợi khoảng 1 phút rồi thử lại.';
      case 'Gemini did not respond before the request timed out.':
        return 'AI phản hồi quá lâu (timeout máy chủ). Thử lại sau ít phút.';
      case 'Gemini could not be reached.':
        return 'Không kết nối được tới Gemini. Kiểm tra mạng máy chủ hoặc thử lại.';
      case 'Gemini rejected the project suggestion request.':
        return 'Yêu cầu gợi ý AI bị từ chối. Kiểm tra nội dung gửi lên.';
      case 'Gemini could not generate a project suggestion.':
        return 'Không tạo được gợi ý AI. Thử lại sau.';
      case 'Gemini did not return a project suggestion.':
      case 'Gemini returned an incomplete project suggestion.':
      case 'Gemini returned an invalid project suggestion.':
        return 'AI trả về dữ liệu chưa đủ. Thử lại sau.';
      case 'An unexpected error occurred.':
        return 'Máy chủ gặp lỗi khi xử lý gợi ý AI. Kiểm tra cấu hình Gemini hoặc thử lại sau.';
      case 'Bạn không có quyền truy cập tài liệu của nhóm này.':
        return 'Bạn không có quyền xem tài liệu nhóm này '
            '(chỉ GVHD hoặc GV được phân công review).';
      case 'Chỉ giảng viên được sử dụng AI phân tích tài liệu.':
        return 'Chỉ giảng viên mới dùng được AI phân tích tài liệu.';
      case 'Không tìm thấy tài liệu.':
        return 'Không tìm thấy tài liệu.';
      case 'Tệp không còn tồn tại trong kho lưu trữ.':
        return 'File tài liệu không còn trên máy chủ.';
      case 'AI chỉ phân tích PDF, DOCX hoặc TXT; hãy giải nén trước khi tải lên.':
        return 'AI chỉ phân tích PDF, DOCX hoặc TXT. File ZIP cần giải nén trước.';
      case 'Không trích xuất được nội dung văn bản từ tài liệu.':
        return 'Không đọc được nội dung văn bản từ tài liệu để phân tích AI.';
      case 'Enter the correct review session access code before opening this session.':
        return 'Cần nhập đúng mã truy cập buổi review trước khi mở phiên này.';
      case 'The review session access code is incorrect.':
        return 'Mã truy cập buổi review không đúng.';
      case 'The Training Department has not generated an access code for this review session.':
        return 'Phòng Đào tạo chưa tạo mã truy cập cho buổi review này.';
      case 'The review session access code must contain exactly 8 valid characters.':
        return 'Mã truy cập phải đúng 8 ký tự hợp lệ.';
      case 'Only a lecturer assigned to this review session can enter its access code.':
        return 'Chỉ giảng viên được phân công mới nhập được mã truy cập buổi này.';
      case 'You are not assigned to this review session.':
        return 'Bạn không được phân công buổi review này.';
      case 'Attendance opens when slot 1 starts.':
      case 'Attendance opens when slot 2 starts.':
      case 'Attendance opens when slot 3 starts.':
      case 'Attendance opens when slot 4 starts.':
      case 'Attendance opens when slot 5 starts.':
        return raw
            .replaceFirst(
              'Attendance opens when slot ',
              'Điểm danh chỉ mở khi Slot ',
            )
            .replaceFirst(' starts.', ' bắt đầu.');
      case 'All reviewer submissions are required before completion.':
        return 'Cần mọi giảng viên được phân công gửi nhận xét trước khi kết thúc buổi.';
      default:
        if (raw.startsWith('Attendance opens when slot ')) {
          final slot = raw
              .replaceFirst('Attendance opens when slot ', '')
              .replaceFirst(' starts.', '');
          return 'Điểm danh chỉ mở khi Slot $slot bắt đầu.';
        }
        return raw;
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => message;
}
