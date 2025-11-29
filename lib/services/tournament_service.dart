import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TournamentService {
  final String baseUrl = AuthService.baseUrl;

  Future<Map<String, dynamic>> generateBracket() async {
    final response = await http.post(Uri.parse('$baseUrl/tournament/generate'));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Failed to generate tournament');
    }
  }
}
