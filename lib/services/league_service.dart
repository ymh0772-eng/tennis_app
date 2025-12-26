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
    int teamAPlayer1Id,
    int teamAPlayer2Id,
    int teamBPlayer1Id,
    int teamBPlayer2Id,
    int scoreTeamA,
    int scoreTeamB,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'team_a_player1_id': teamAPlayer1Id,
        'team_a_player2_id': teamAPlayer2Id,
        'team_b_player1_id': teamBPlayer1Id,
        'team_b_player2_id': teamBPlayer2Id,
        'score_team_a': scoreTeamA,
        'score_team_b': scoreTeamB,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit match');
    }
  }
}
