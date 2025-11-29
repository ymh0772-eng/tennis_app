import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ScheduleService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<dynamic>> fetchSchedules() async {
    final response = await http.get(Uri.parse('$baseUrl/schedules'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> createSchedule(
    String memberName,
    String startTime,
    String endTime,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schedules'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'member_name': memberName,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Failed to create schedule');
    }
  }
}
