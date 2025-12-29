import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/match_record.dart';

class MatchService {
  final _authService = AuthService();
  final String baseUrl = AuthService.baseUrl;

  Future<List<MatchRecord>> getMatches() async {
    final token = await _authService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/matches'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // Vital: Decode bytes to utf8 to handle Korean characters correcty
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MatchRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load matches: ${response.statusCode}');
    }
  }

  Future<void> deleteMatch(int id) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/matches/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete match: ${response.body}');
    }
  }
}
