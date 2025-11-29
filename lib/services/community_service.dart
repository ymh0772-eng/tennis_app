import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CommunityService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(Uri.parse('$baseUrl/community'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> createPost(
    String title,
    String authorName,
    String content,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'author_name': authorName,
        'content': content,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create post');
    }
  }

  Future<void> deletePost(int postId, String password) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/community/$postId?password=$password'),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 403) {
        throw Exception('비밀번호가 일치하지 않습니다.');
      }
      throw Exception('Failed to delete post');
    }
  }
}
