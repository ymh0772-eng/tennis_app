import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LeagueService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<dynamic>> fetchRankings() async {
    final response = await http.get(Uri.parse('$baseUrl/league/rankings'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load rankings');
    }
  }

  Future<void> submitMatch(
    int player1Id,
    int player2Id,
    int score1,
    int score2,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'player1_id': player1Id,
        'player2_id': player2Id,
        'score1': score1,
        'score2': score2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit match');
    }
  }
}
