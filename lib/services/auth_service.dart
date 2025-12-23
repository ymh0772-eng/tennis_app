import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl =>
      'https://mhyunhome.duckdns.org'; // Use actual IP for physical device testing

  static String? accessToken; // Optional: Keep for quick access
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );

    // 1. 상세 디버깅 로그 추가
    print('📦 서버 응답 상태 코드: ${response.statusCode}');
    print('📦 서버 응답 본문: ${utf8.decode(response.bodyBytes)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      // 2. 토큰 파싱 강화 (Null Safety)
      final token =
          data['access_token'] ?? data['accessToken'] ?? data['token'];

      if (token != null) {
        // 3. 저장소 로직 확인
        accessToken = token;
        await _storage.write(key: 'access_token', value: accessToken);
        print('✅ 토큰 저장 완료: $accessToken');
      } else {
        print('⚠️ 경고: 응답에서 토큰을 찾을 수 없습니다.');
      }
      return data;
    } else {
      throw Exception(
        jsonDecode(utf8.decode(response.bodyBytes))['detail'] ?? 'Login failed',
      );
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String birth,
    String pin,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/members/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'birth': birth,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<List<dynamic>> fetchPendingUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users/pending'));
    if (response.statusCode == 200) {
      print('DEBUG: 원본 데이터(Pending): ${utf8.decode(response.bodyBytes)}');
      final List<dynamic> rawList = jsonDecode(utf8.decode(response.bodyBytes));
      // Sanitize data using User model with fail-safe map
      return rawList
          .map((json) {
            try {
              return User.fromJson(json).toJson();
            } catch (e) {
              print('⚠️ Parse Error (ID: ${json['id']}): $e');
              return null;
            }
          })
          .where((item) => item != null)
          .toList();
    } else {
      throw Exception('Failed to load pending users');
    }
  }

  Future<List<dynamic>> fetchMembers() async {
    final response = await http.get(Uri.parse('$baseUrl/members/'));
    if (response.statusCode == 200) {
      print('DEBUG: 원본 데이터(Members): ${utf8.decode(response.bodyBytes)}');
      final List<dynamic> rawList = jsonDecode(utf8.decode(response.bodyBytes));
      // Sanitize data using User model with fail-safe map
      return rawList
          .map((json) {
            try {
              return User.fromJson(json).toJson();
            } catch (e) {
              print('⚠️ Parse Error (ID: ${json['id']}): $e');
              return null;
            }
          })
          .where((item) => item != null)
          .toList();
    } else {
      throw Exception('Failed to load members');
    }
  }

  // Backend Endpoint: PUT /users/{id}/approve (preferred) or /members/{phone}/approve
  // Returns null if successful, otherwise returns error message
  Future<String?> approveMember(String phone, {int? id}) async {
    Uri url;
    if (id != null) {
      // Try ID-based endpoint first as suggested by 404 error
      url = Uri.parse('$baseUrl/users/$id/approve');
      print("📡 승인 요청 발송 (ID): $id -> $url");
    } else {
      url = Uri.parse('$baseUrl/members/$phone/approve');
      print("📡 승인 요청 발송 (Phone): $phone -> $url");
    }

    try {
      // 1. Read token from storage
      final token = await _storage.read(key: 'access_token');

      if (token == null) {
        print('❌ 토큰 없음: 로그인이 필요합니다.');
        return '인증 정보가 없습니다. 다시 로그인해주세요.';
      }

      print(
        '🔑 사용 토큰: ${token.substring(0, 10)}...',
      ); // Log partial token for debugging

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        print("✅ 승인 성공: ${response.body}");
        return null; // Success
      } else {
        final errorMsg = "오류: ${response.statusCode} - ${response.body}";
        print("❌ 승인 실패: $errorMsg");
        return errorMsg;
      }
    } catch (e) {
      print("❌ 통신 에러: $e");
      return "통신 에러: $e";
    }
  }
}
