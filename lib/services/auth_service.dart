import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl =>
      'https://mhyunhome.duckdns.org'; // Use actual IP for physical device testing

  Future<Map<String, dynamic>> login(String phone, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
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

  Future<void> approveMember(String phone) async {
    final response = await http.put(
      Uri.parse('$baseUrl/members/$phone/approve'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve member');
    }
  }
}
