import 'package:flutter/material.dart';
import '../services/league_service.dart';

class LeagueHistoryScreen extends StatefulWidget {
  const LeagueHistoryScreen({super.key});

  @override
  State<LeagueHistoryScreen> createState() => _LeagueHistoryScreenState();
}

class _LeagueHistoryScreenState extends State<LeagueHistoryScreen> {
  final _leagueService = LeagueService();

  // 날짜 선택 변수 (기본값: 현재 날짜)
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<dynamic> _historyList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 화면 켜지면 데이터 조회 (단, 지난달 데이터가 없을 수도 있으니 빈 화면으로 시작)
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    // 서비스 호출
    final data = await _leagueService.fetchLeagueHistory(
      _selectedYear,
      _selectedMonth,
    );
    setState(() {
      _historyList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('월별 명예의 전당'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. 날짜 선택 필터
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 연도 선택 (간소화: -1년, +1년 버튼)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedYear--;
                        _selectedMonth = 12;
                      } else {
                        _selectedMonth--;
                      }
                    });
                    _fetchHistory();
                  },
                ),
                Text(
                  '$_selectedYear년 $_selectedMonth월',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedYear++;
                        _selectedMonth = 1;
                      } else {
                        _selectedMonth++;
                      }
                    });
                    _fetchHistory();
                  },
                ),
              ],
            ),
          ),

          // 2. 기록 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyList.isEmpty
                ? const Center(child: Text("기록된 데이터가 없습니다."))
                : ListView.builder(
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      final item = _historyList[index];
                      // 멤버 이름이 null일 수 있으므로 처리
                      final name = item['member'] != null
                          ? item['member']['name']
                          : '알 수 없음';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index < 3
                                ? Colors.amber
                                : Colors.grey[300],
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item['final_wins']}승 ${item['final_losses']}패',
                          ),
                          trailing: Text(
                            '${item['total_points']}점',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
