import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/member.dart';

class AuthService {
  // 서버 주소
  static const String baseUrl = 'http://mhyunhome.duckdns.org';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 1. 로그인
  Future<Member?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      print('Login Status: ${response.statusCode}'); // [디버깅]

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String token = data['access_token'];

        await _storage.write(key: 'access_token', value: token);
        return await _getMe(token);
      } else {
        print('Login failed Body: ${utf8.decode(response.bodyBytes)}'); // [디버깅]
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // 2. 회원가입
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

  // 3. 회원 목록 불러오기 (토큰 추가 수정됨 ✅)
  Future<List<Member>> fetchMembers({bool? isApproved}) async {
    final token = await getToken(); // 토큰 가져오기
    String url = '$baseUrl/members/';
    if (isApproved != null) {
      url += '?is_approved=$isApproved'; // 쿼리 파라미터 수정 (백엔드에 맞춤)
    }

    // 헤더에 토큰 추가
    final response = await http.get(
      Uri.parse(url),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(utf8.decode(response.bodyBytes));
      return rawList.map((json) => Member.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load members');
    }
  }

  // 4. 회원 승인
  Future<String?> approveMember(String phone, {required int id}) async {
    final token = await getToken();
    if (token == null) return '인증 정보가 없습니다.';

    // URL 수정 (백엔드 라우터 규칙 확인 필요, 보통 approve 동사 사용)
    final url = Uri.parse('$baseUrl/members/$id/approve');
    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return "오류: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}";
      }
    } catch (e) {
      return "통신 에러: $e";
    }
  }

  // 5. 내 정보 가져오기 (여기가 핵심! 🕵️)
  Future<Member?> _getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // [디버깅] 서버가 보내준 진짜 데이터를 터미널에 찍어봅니다.
      print('--- [DEBUG] Server Response (/users/me) ---');
      print(utf8.decode(response.bodyBytes));
      print('-------------------------------------------');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Member.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get Me error: $e');
      return null;
    }
  }

  // 6. 로그아웃
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  // 7. 토큰 가져오기
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // 8. 회원 삭제
  Future<void> deleteMember(int memberId) async {
    final token = await getToken();
    if (token == null) throw Exception("로그인이 필요합니다.");

    final response = await http.delete(
      Uri.parse('$baseUrl/members/$memberId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('회원 삭제 실패: ${response.statusCode}');
    }
  }

  // 9. 현재 멤버 가져오기
  Future<Member?> getCurrentMember() async {
    final token = await getToken();
    if (token == null) return null;
    return await _getMe(token);
  }
}
