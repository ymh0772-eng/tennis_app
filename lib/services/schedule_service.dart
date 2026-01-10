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

  Future<bool> createSchedule(String startTime, String endTime) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    // Time Formatting (HH:MM -> HH:MM:00)
    String formattedStart = startTime.length == 5 ? "$startTime:00" : startTime;
    String formattedEnd = endTime.length == 5 ? "$endTime:00" : endTime;

    // Date Formatting (YYYY-MM-DD)
    String todayDate = DateTime.now().toIso8601String().split('T')[0];

    final response = await http.post(
      Uri.parse('$baseUrl/schedules'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'start_time': formattedStart,
        'end_time': formattedEnd,
        'date': todayDate,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Error 422 Detail: ${utf8.decode(response.bodyBytes)}');
      return false;
    }
  }

  // Edit Schedule (PUT)
  Future<bool> updateSchedule(int id, String startTime, String endTime) async {
    final url = Uri.parse('$baseUrl/schedules/$id');
    final token = await AuthService().getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "start_time": startTime,
          "end_time": endTime,
          // Maintain current date or handle as needed
          "date": DateTime.now().toIso8601String().split('T')[0],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Schedule update error: $e");
      return false;
    }
  }

  // Delete Schedule (DELETE)
  Future<bool> deleteSchedule(int id) async {
    final url = Uri.parse('$baseUrl/schedules/$id');
    final token = await AuthService().getToken();

    try {
      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Schedule delete error: $e");
      return false;
    }
  }
}
