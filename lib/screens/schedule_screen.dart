import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String memberName;

  const ScheduleScreen({super.key, required this.memberName});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleService = ScheduleService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final schedules = await _scheduleService.fetchSchedules();
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSchedule() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (picked.hour < 6 || picked.hour >= 22) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('운동 가능 시간은 06시부터 22시까지입니다')),
          );
        }
        return;
      }

      final startHour = picked.hour.toString().padLeft(2, '0');
      final startMinute = picked.minute.toString().padLeft(2, '0');
      final startTime = '$startHour:$startMinute';

      // Auto-calculate end time (+2 hours)
      final endHourInt = picked.hour + 2;
      final endHour = endHourInt > 23 ? 23 : endHourInt; // Cap at 23
      final endTime = '${endHour.toString().padLeft(2, '0')}:$startMinute';

      try {
        await _scheduleService.createSchedule(
          widget.memberName,
          startTime,
          endTime,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('운동 약속이 등록되었습니다')));
          _loadSchedules();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 약속'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? const Center(
              child: Text(
                '오늘 예정된 운동 약속이 없습니다.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    title: Text(
                      schedule['member_name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '${schedule['start_time']} ~ ${schedule['end_time']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSchedule,
        child: const Icon(Icons.add),
      ),
    );
  }
}
