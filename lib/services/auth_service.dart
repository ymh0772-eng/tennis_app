import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class AuthService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl =>
      'http://121.178.252.63:8000'; // Use actual IP for physical device testing

  Future<Map<String, dynamic>> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw AuthException(
        body['detail'] ?? 'Login failed',
        response.statusCode,
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

  Future<List<dynamic>> fetchMembers() async {
    final response = await http.get(Uri.parse('$baseUrl/members/'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load members');
    }
  }

  Future<List<dynamic>> fetchPendingUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users/pending'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load pending users');
    }
  }

  // Backend Endpoint: PUT /members/{phone}/approve
  Future<bool> approveMember(String phone) async {
    final url = Uri.parse('$baseUrl/members/$phone/approve');

    try {
      print("📡 승인 요청 발송: $phone -> $url");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        print("✅ 승인 성공: ${response.body}");
        return true;
      } else {
        print("❌ 승인 실패: ${response.statusCode} / ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ 통신 에러: $e");
      return false;
    }
  }
}
