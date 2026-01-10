import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String memberName;

  const ScheduleScreen({super.key, required this.memberName});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _authService = AuthService();
  final _scheduleService = ScheduleService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSchedules();
  }

  Future<void> _loadCurrentUser() async {
    final member = await _authService.getCurrentMember();
    if (mounted && member != null) {
      setState(() {
        _currentUserId = member.id;
      });
    }
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
    FocusScope.of(context).unfocus(); // 키보드 내리기
    await Future.delayed(const Duration(milliseconds: 100)); // UI 안정성 확보

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

      bool success = await _scheduleService.createSchedule(startTime, endTime);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('운동 약속이 등록되었습니다')));
          _loadSchedules();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('등록 실패: 입력 정보를 확인해주세요')));
        }
      }
    }
  }

  void _showDeleteConfirmDialog(int scheduleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('약속 취소'),
        content: const Text('정말 이 운동 약속을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // 팝업 닫기

              // 삭제 요청
              bool success = await _scheduleService.deleteSchedule(scheduleId);
              if (success) {
                _loadSchedules(); // [중요] 리스트 새로고침
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('삭제 실패')));
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> schedule) async {
    // Parse existing start time
    final times = schedule['start_time'].split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(times[0]),
      minute: int.parse(times[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: "시작 시간 변경",
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
      final endHour = endHourInt > 23 ? 23 : endHourInt;
      final endTime = '${endHour.toString().padLeft(2, '0')}:$startMinute';

      bool success = await _scheduleService.updateSchedule(
        schedule['id'],
        startTime,
        endTime,
      );

      if (success) {
        _loadSchedules();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('수정 실패')));
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
                // Check if this schedule belongs to the current user
                // Assuming 'member_id' is available in the schedule map
                bool isMine =
                    _currentUserId != null &&
                    schedule['member_id'] == _currentUserId;

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
                    subtitle: Text(
                      '${schedule['start_time']} ~ ${schedule['end_time']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: isMine
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (String value) {
                              if (value == 'edit') {
                                _showEditDialog(schedule);
                              } else if (value == 'delete') {
                                _showDeleteConfirmDialog(schedule['id']);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('시간 수정'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          )
                        : null,
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
